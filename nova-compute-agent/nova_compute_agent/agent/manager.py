# coding=utf-8

import os
import eventlet
try:
    from oslo.config import cfg
except ImportError:
    from oslo_config import cfg

try:
    from oslo import messaging
except ImportError:
    import oslo_messaging as messaging

from nova_compute_agent import constant
from nova_compute_agent.handle import evacuate
from nova_compute_agent.handle import ipmi as ipmi_handler
from nova_compute_agent.handle import migrate
from nova_compute_agent.inspect import ipmi
from nova_compute_agent.inspect import nic
from nova_compute_agent.inspect import ping
from nova_compute_agent.openstack.common import log as logging
from nova_compute_agent.openstack.common import periodic_task
from nova_compute_agent.openstack.common import jsonutils
from nova_compute_agent import utils
CONF = cfg.CONF
LOG = logging.getLogger(__name__)
nova_compute_agent_opts = [
 cfg.BoolOpt('dry_run', default=True, help='Just record actions, do not take action.'),
 cfg.IntOpt('check_interval', default=20, help='The interval time to check hosts health'),
 cfg.IntOpt('fault_hosts_number_threshold', default=2, help='Take action when fault host number is <= this value'),
 cfg.ListOpt('ignore_hosts', default=[], help='host names which we do not care about.'),
 cfg.ListOpt('only_hosts', default=[], help='Host names which we only care about'),
 cfg.ListOpt('mixed_hosts', default=[], help='host names which mixed with storage.'),
 cfg.ListOpt('non_mixed_hosts', default=[], help='Host names which non_mixed with storage')]
CONF.register_opts(nova_compute_agent_opts)

class HostHAManager(periodic_task.PeriodicTasks):
    import pdb; pdb.set_trace()
    target = messaging.Target(version='1.0')
    actions_mapping = {'FAILED_OK_OK_OK_OK': [constant.EVACUATION],'OK_OK_OK_FAILED_OK': [
                            constant.MIGRATION],
       'OK_OK_OK_FAILED_FAILED': [
                                constant.MIGRATION],
       'OK_FAILED_OK_OK_FAILED': [
                                constant.IPMI_POWER_OFF, constant.EVACUATION],
       'OK_FAILED_FAILED_OK_FAILED': [
                                    constant.IPMI_POWER_OFF, constant.EVACUATION],
       'OK_FAILED_OK_FAILED_FAILED': [
                                    constant.IPMI_POWER_OFF, constant.EVACUATION]
       }

    def __init__(self, host=None, service_name='hostha'):
        if not host:
            host = CONF.host
        self.host = host
        self.service_name = service_name
        self.ipmi = ipmi.IPMIInspector()
        self.nic = nic.NicInspector()
        self.ping = ping.PingInspector()
        self.handlers_mapping = {}
        self.last_hosts_statics = {}
        if CONF.ignore_hosts and CONF.only_hosts:
            raise Exception('Must set only one of ignore_hosts and only_hosts')
        if CONF.mixed_hosts and CONF.non_mixed_hosts:
            raise Exception('Must set only one of mixed_hosts and non_mixed_hosts')
        super(HostHAManager, self).__init__()

    def get_handler(self, action):
        if not self.handlers_mapping:
            self.handlers_mapping[constant.EVACUATION] = evacuate.EvacuateHandler()
            self.handlers_mapping[constant.IPMI_POWER_OFF] = ipmi_handler.IPMIPowerOffHandler()
            self.handlers_mapping[constant.MIGRATION] = migrate.MigrateHandler()
        return self.handlers_mapping.get(action)

    def periodic_tasks(self, context, raise_on_error=False):
        """Tasks to be run at a periodic interval."""
        return self.run_periodic_tasks(context, raise_on_error=raise_on_error)

    def init_host(self):
        """Hook to do additional manager initialization when one requests
        the service be started.  This is called before any service record
        is created.
        
        Child classes should override this method.
        """
        pass

    def cleanup_host(self):
        """Hook to do cleanup work when the service shuts down.
        
        Child classes should override this method.
        """
        pass

    def filter_hosts(self, hosts):
        if CONF.ignore_hosts:
            hosts = [ host for host in hosts if host not in CONF.ignore_hosts ]
        elif CONF.only_hosts:
            hosts = [ host for host in hosts if host in CONF.only_hosts ]
        return hosts

    def _check_host(self, host):
        host_state = [
         constant.UNKNOWN, constant.UNKNOWN, constant.UNKNOWN,
         constant.UNKNOWN, constant.UNKNOWN, constant.UNKNOWN]
        host_state[5] = utils.get_host_az(host=host)
        host_state[0] = self.ipmi.check(host)
        if host_state[0] == constant.FAILED:
            return host_state
        ping_result = self.ping.check(host)
        host_state[1] = ping_result.get(constant.CEPH_PUBLIC_IP, constant.UNKNOWN)
        host_state[2] = ping_result.get(constant.MANAGEMENT_IP, constant.UNKNOWN)
        host_state[3] = self.nic.check(host)
        host_state[4] = self._check_mixed_storage(host)
        return host_state

    def _check_mixed_storage(self, host):
        if CONF.mixed_hosts:
            if host in CONF.mixed_hosts:
                return constant.OK
            else:
                return constant.FAILED

        if CONF.non_mixed_hosts:
            if host in CONF.non_mixed_hosts:
                return constant.FAILED
            else:
                return constant.OK

        return constant.UNKNOWN

    def _take_action(self, host, action):
        for act in action:
            try:
                handler = self.get_handler(act)
                if handler:
                    handler.handle_host(host)
            except:
                LOG.warning('Failed to take action %s, skip following actions' % act)
                break

    def check_hosts(self, hosts):
        hosts_statics = {}
        pile = eventlet.GreenPile()
        for host in hosts:
            pile.spawn(self._check_host, host)

        for host, host_state in zip(hosts, pile):
            hosts_statics[host] = host_state

        return hosts_statics

    def _compare_with_last_time(self, hosts_statics):
        final_hosts_statics = {}
        for host, host_state in hosts_statics.items():
            if self.last_hosts_statics.get(host) == host_state:
                final_hosts_statics[host] = host_state

        self.last_hosts_statics = hosts_statics
        return final_hosts_statics

    def do_actions(self, hosts_statics):
        LOG.info('Host status in format ( power_status, ceph-public, management_ip, production_nic, mixed_storage, az)')
        LOG.info('current check hosts results: %s' % hosts_statics)
        final_hosts_statics = self._compare_with_last_time(hosts_statics)
        LOG.info('final check hosts results: %s' % final_hosts_statics)
        final_hosts_statics = utils.filter_hosts_by_threshold(final_hosts_statics, CONF.fault_hosts_number_threshold)
        if len(final_hosts_statics) < 1:
            LOG.info('After filtering by threshold.no host need to be taken action, just return')
            return
        LOG.info('After filtering by threshold, actions will be taken on %s', final_hosts_statics.keys())
        actions = {}
        for host, state in final_hosts_statics.items():
            converted_state = [ constant.OK if 1 else it for it in state[:5] if it == constant.UNKNOWN
                              ]
            state_str = '_'.join([ it for it in converted_state ])
            action = self.actions_mapping.get(state_str)
            if action:
                actions[host] = action

        if CONF.dry_run:
            LOG.info('Config option dry_run=True, skip actions: %s' % actions)
            return
        for host, action in actions.items():
            LOG.info('Host HA disable compute service on host %s' % host)
            utils.disable_service(host)

        if actions:
            LOG.info('Take actions: %s' % actions)
        for host, action in actions.items():
            self._take_action(host, action)

    def skip_host_ha(self):
        file_path = '/etc/nova-compute-agent/enable_ha.conf'
        if not os.path.exists(file_path):
            return False
        disable = False
        with open(file_path) as f:
            for line in f.readlines():
                if line.startswith('#') or len(line) == 0:
                    continue
                if line.strip() == '0':
                    disable = True

        return disable

    @periodic_task.periodic_task(spacing=CONF.check_interval)
    def do_compute_host_ha(self, context):
        """periodical task for compute host HA"""
        if self.skip_host_ha():
            LOG.info('skip Host HA by user')
            return
        hosts = utils.get_all_hosts(binary='nova-compute', servers=False)
        hosts = self.filter_hosts(hosts)
        hosts_statics = self.check_hosts(hosts)
        self.do_actions(hosts_statics)
