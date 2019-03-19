# coding=utf-8

"""Utilities and helper functions"""
import calendar
from datetime import datetime
import os
import random
import time
try:
    from oslo.config import cfg
except ImportError:
    from oslo_config import cfg

from novaclient import client as novaclient
import prettytable
from nova_compute_agent import constant
from nova_compute_agent.openstack.common import processutils
from nova_compute_agent.openstack.common import log as logging
LOG = logging.getLogger(__name__)
CONF = cfg.CONF
auth_opts = [
 cfg.StrOpt('username', default='admin', help='Admin project user name.'),
 cfg.StrOpt('password', default='admin', help='Admin project user password.'),
 cfg.StrOpt('auth_url', default='http://127.0.0.1:5000/v2.0', help='KeyStone auth URL'),
 cfg.StrOpt('project_id', default='admin', help='Admin project id'),
 cfg.StrOpt('region_name', default='RegionOne', help='Region name')]
common_opts = [
 cfg.BoolOpt('on_shared_storage', default=True, help='Instance root disk on share storage or not.'),
 cfg.BoolOpt('action_in_same_aggregate', default=False, help='evacuate or live-migration in same aggregate.'),
 cfg.IntOpt('evacuate_interval', default=1, help='sleep seconds between two evacuate server actions.take action only when evacuate_interval > 0'),
 cfg.ListOpt('evacuate_target_hosts', default=None, help='Target host names when evacuate instance.'),
 cfg.IntOpt('service_down_time', default=60, help='Maximum time since last check-in for up service'),
 cfg.BoolOpt('account_for_az', default=False, help='Account fault hosts in available zone, default is False,means in a region.'),
 cfg.StrOpt('novaclient_version', default='2', help='novaclient version')]
CONF.register_opts(auth_opts, 'Auth')
CONF.register_opts(common_opts)

class HostEvacuateResponse(object):

    def __init__(self, server_uuid, evacuate_accepted, error_message):
        self.server_uuid = server_uuid
        self.evacuate_accepted = evacuate_accepted
        self.error_message = error_message


class HostMigrateResponse(object):

    def __init__(self, server_uuid, migrate_accepted, error_message):
        self.server_uuid = server_uuid
        self.migrate_accepted = migrate_accepted
        self.error_message = error_message


class HostEvacuateLiveResponse(object):

    def __init__(self, server_uuid, live_migration_accepted, error_message):
        self.server_uuid = server_uuid
        self.live_migration_accepted = live_migration_accepted
        self.error_message = error_message


def _get_nova_client():
    creds = {}
    creds['username'] = CONF.Auth.username
    creds['api_key'] = CONF.Auth.password
    creds['auth_url'] = CONF.Auth.auth_url
    creds['project_id'] = CONF.Auth.project_id
    creds['endpoint_type'] = 'adminURL'
    creds['region_name'] = CONF.Auth.region_name
    return novaclient.Client(CONF.novaclient_version, **creds)


def get_host_az(nova_client=None, host=None, binary='nova-compute'):
    """get availability-zone of the given host"""
    if nova_client is None:
        nova_client = _get_nova_client()
    service = nova_client.services.list(binary=binary, host=host)
    return service[0].zone


def get_all_hosts(nova_client=None, binary=None, status='enabled', state='all', servers=True):
    """ get all service's host names, state can be down/up/all,
        If set servers, only return hosts which have server
    """
    self_disabled_reason = [
     'set by xenapi host_state',
     'Failed to connect to libvirt',
     'Connection to libvirt lost',
     'Connection to libvirt failed']
    all_hosts = []
    services = []
    if nova_client is None:
        nova_client = _get_nova_client()
    if binary is not None:
        services = nova_client.services.list(binary=binary)
    else:
        services = nova_client.services.list()
    for service in services:
        if status == service.status:
            all_hosts.append(service.host)
        if status == 'enabled' and service.status == 'disabled':
            if service.disabled_reason and any([ reason in service.disabled_reason for reason in self_disabled_reason
                                               ]):
                all_hosts.append(service.host)

    hosts = list(set(all_hosts))
    if servers and binary == 'nova-compute':
        hosts = [ host for host in hosts if _has_instances(nova_client, host) ]
    return hosts


def disable_service(host_name, nova_client=None, binary='nova-compute'):
    if nova_client is None:
        nova_client = _get_nova_client()
    nova_client.services.disable_log_reason(host_name, binary, 'Disabled by Host HA')
    return


def _has_instances(nova_client=None, host_name=None):
    if host_name is None:
        return False
    else:
        if nova_client is None:
            nova_client = _get_nova_client()
        search_opts = dict(host=host_name, all_tenants=True)
        servers = nova_client.servers.list(search_opts=search_opts)
        return len(servers) != 0


def list_instances(nova_client=None, host=None):
    if host is None:
        return
    else:
        if nova_client is None:
            nova_client = _get_nova_client()
        search_opts = dict(host=host, all_tenants=True)
        servers = nova_client.servers.list(search_opts=search_opts)
        mixed_case_fields = ['serverId']
        fields = [
         'ID',
         'Name',
         'Status',
         'Networks']
        pt = prettytable.PrettyTable([ f for f in fields ], caching=False)
        pt.align = 'l'
        for o in servers:
            row = []
            for field in fields:
                if field in mixed_case_fields:
                    field_name = field.replace(' ', '_')
                else:
                    field_name = field.lower().replace(' ', '_')
                data = getattr(o, field_name, '')
                if data is None:
                    data = '-'
                row.append(data)

            pt.add_row(row)

        LOG.info('instance lists on %s :' % host)
        LOG.info(pt.get_string())
        return


def _get_same_ag_hosts(nova_client=None, host=None):
    same_ag_hosts = []
    aggregates = nova_client.aggregates.list()
    for a in aggregates:
        if host in a.hosts:
            same_ag_hosts.extend(a.hosts)

    same_ag_hosts = list(set(same_ag_hosts))
    return same_ag_hosts


def _select_target_host(nova_client=None, server=None, ignore_hosts=[], target_hosts=[]):
    """Select evacuate target host."""
    if nova_client is None:
        nova_client = _get_nova_client()
    instance = nova_client.servers.get(server['uuid'])
    orig_host = instance.__dict__['OS-EXT-SRV-ATTR:host']
    flavor_id = instance.flavor['id']
    flavor = nova_client.flavors.get(flavor_id)
    ram_mb, disk = flavor.ram, flavor.disk + flavor.ephemeral
    selected_hypervisor = []
    services = nova_client.services.list(binary='nova-compute')
    up_hosts = [ service.host for service in services if service.state == 'up' and service.status == 'enabled'
               ]
    default_nova_hosts = []
    is_nova_host = False
    for service in services:
        if service.status == 'enabled' and service.zone == 'nova' and service.state == 'up':
            default_nova_hosts.append(service.host)
        if service.zone == 'nova' and service.host == orig_host:
            is_nova_host = True

    if is_nova_host:
        same_ag_hosts = default_nova_hosts
    else:
        same_ag_hosts = _get_same_ag_hosts(nova_client, orig_host)
    hypervisors = nova_client.hypervisors.list()
    for hypervisor in hypervisors:
        if hypervisor.hypervisor_hostname == orig_host:
            continue
        if hypervisor.hypervisor_hostname not in up_hosts:
            continue
        free_ram_mb = hypervisor.free_ram_mb
        free_disk_gb = hypervisor.free_disk_gb
        if (
         free_ram_mb, free_disk_gb) > (ram_mb, disk):
            if hypervisor.hypervisor_hostname in ignore_hosts:
                continue
            selected_hypervisor.append(hypervisor.hypervisor_hostname)

    if len(selected_hypervisor) == 0:
        return
    else:
        if target_hosts:
            available_target_hosts = []
            for host in target_hosts:
                if host in selected_hypervisor:
                    available_target_hosts.append(host)

            if available_target_hosts:
                return random.choice(available_target_hosts)
            else:
                LOG.warning('No available target hosts: %s' % target_hosts)
                return

        random.shuffle(same_ag_hosts)
        for h in same_ag_hosts:
            if h in selected_hypervisor:
                return h

        if CONF.action_in_same_aggregate:
            return
        return random.choice(selected_hypervisor)


def do_host_evacuate(nova_client=None, host=None):
    """Evacuate all instances from failed host."""
    response = []
    if not CONF.on_shared_storage:
        LOG.warning('Evacuate must within share storage, skip the action')
        return response
    else:
        if nova_client is None:
            nova_client = _get_nova_client()
        services = nova_client.services.list(binary='nova-compute', host=host)
        if len(services) == 1 and services[0].state == 'up':
            time.sleep(CONF.service_down_time + 1)
        hypervisors = nova_client.hypervisors.search(host, servers=True)
        for hyper in hypervisors:
            if hasattr(hyper, 'servers'):
                for server in hyper.servers:
                    if CONF.evacuate_interval > 0:
                        time.sleep(CONF.evacuate_interval)
                    response.append(_server_evacuate(nova_client, server))

        return response


def do_host_migrate(nova_client=None, host=None):
    """Migrate all instances from specific host."""
    if nova_client is None:
        nova_client = _get_nova_client()
    hypervisors = nova_client.hypervisors.search(host, servers=True)
    response = []
    for hyper in hypervisors:
        if hasattr(hyper, 'servers'):
            for server in hyper.servers:
                if CONF.evacuate_interval > 0:
                    time.sleep(CONF.evacuate_interval)
                response.append(_server_migrate(nova_client, server))

    return response


def do_host_evacuate_live(nova_client=None, host=None, ignore_hosts=[]):
    """Live migrate all instances of the specified host
    to other available hosts.
    """
    if nova_client is None:
        nova_client = _get_nova_client()
    hypervisors = nova_client.hypervisors.search(host, servers=True)
    response = []
    for hyper in hypervisors:
        for server in getattr(hyper, 'servers', []):
            if CONF.evacuate_interval > 0:
                time.sleep(CONF.evacuate_interval)
            response.append(_server_live_migrate(nova_client, server, ignore_hosts))

    return response


def _server_evacuate(nova_client=None, server=None):
    """Evacuate one instance."""
    if nova_client is None:
        nova_client = _get_nova_client()
    success = True
    error_message = ''
    try:
        target_host = _select_target_host(nova_client, server, target_hosts=CONF.evacuate_target_hosts)
        if target_host is None:
            raise Exception("Can't find target host")
        instance = nova_client.servers.get(server['uuid'])
        if instance.status == 'SHUTOFF':
            dt = datetime.strptime(instance.updated, '%Y-%m-%dT%H:%M:%SZ')
            updated_timestap = calendar.timegm(dt.timetuple())
            time_detal = time.time() - updated_timestap
            if time_detal < 300:
                nova_client.servers.reset_state(server=server['uuid'], state='active')
        nova_client.servers.evacuate(server=server['uuid'], host=target_host, on_shared_storage=CONF.on_shared_storage)
    except Exception as e:
        success = False
        error_message = 'Error while evacuating instance: %s' % e

    return HostEvacuateResponse(server['uuid'], success, error_message)


def _server_migrate(nova_client=None, server=None):
    """Migrate one instance."""
    if nova_client is None:
        nova_client = _get_nova_client()
    success = True
    error_message = ''
    try:
        nova_client.servers.migrate(server=server['uuid'])
    except Exception as e:
        success = False
        error_message = 'Error while migrating instance: %s' % e

    return HostMigrateResponse(server['uuid'], success, error_message)


def _server_live_migrate(nova_client=None, server=None, ignore_hosts=[]):
    """Live migration one instance."""
    if nova_client is None:
        nova_client = _get_nova_client()
    success = True
    error_message = ''
    try:
        instance = nova_client.servers.get(server['uuid'])
        if instance.status != 'ACTIVE':
            raise Exception('%s not in active status, skip' % server['uuid'])
        target_host = _select_target_host(nova_client, server, ignore_hosts)
        if target_host is None:
            raise Exception("Can't find target host")
        block_migration = not CONF.on_shared_storage
        instance.live_migrate(target_host, block_migration)
    except Exception as e:
        success = False
        error_message = 'Error while live migrating instance: %s' % e

    return HostEvacuateLiveResponse(server['uuid'], success, error_message)


def execute(*cmd, **kwargs):
    """Convenience wrapper around oslo's execute() method."""
    LOG.debug('Execution command:"%s"', ' '.join(map(str, cmd)))
    result = processutils.execute(*cmd, **kwargs)
    LOG.debug('Command stdout is: "%s"' % result[0])
    LOG.debug('Command stderr is: "%s"' % result[1])
    return result


def delete_if_exists(pathname):
    """delete a file, but ignore file not found error."""
    try:
        os.unlink(pathname)
    except OSError as e:
        if e.errno == errno.ENOENT:
            return
        raise


def _calculate_failure_num(host_state):
    failed_score = [
     0, 0, 0, 0]
    for index, value in enumerate(host_state[:4]):
        if value == constant.FAILED:
            failure = 1 if 1 else 0
            failed_score[index] = failure

    return failed_score


def _calculate_failure_nums(hosts_statics):
    failed_score_sum = [
     0, 0, 0, 0]
    for host, host_state in hosts_statics.items():
        scores = _calculate_failure_num(host_state)
        failed_score_sum = [ x + y for x, y in zip(failed_score_sum, scores) ]

    return failed_score_sum


def _filter_hosts_by_region(hosts_statics, threshold):
    failed_score_sum = _calculate_failure_nums(hosts_statics)
    if any([ num > threshold for num in failed_score_sum ]):
        hosts_statics = {}
    return hosts_statics


def _filter_hosts_by_az(hosts_statics, threshold):
    hosts_statics_with_az_key = {}
    az = []
    for host, host_state in hosts_statics.items():
        az_tag = host_state[-1]
        if not hosts_statics_with_az_key.get(az_tag):
            hosts_statics_with_az_key[az_tag] = _calculate_failure_num(host_state)
        else:
            base_score = hosts_statics_with_az_key.get(az_tag)
            new_score = _calculate_failure_num(host_state)
            hosts_statics_with_az_key[az_tag] = [ x + y for x, y in zip(base_score, new_score) ]

    for zone, failed_score in hosts_statics_with_az_key.items():
        if any([ num > threshold for num in failed_score ]):
            LOG.warning('There are too many failed hosts in %s zone,filter them out of host_list', zone)
            az.append(zone)

    for host, host_state in hosts_statics.items():
        if host_state[-1] in az:
            hosts_statics.pop(host)

    return hosts_statics


def filter_hosts_by_threshold(hosts_statics, threshold):
    """Example of hosts_statics
    
    statics = {
        'host1':['OK', 'OK', 'FAILED', 'UNKNOWN', 'OK', 'netapp'],
        'host2':['OK', 'FAILED', 'FAILED', 'UNKNOWN', 'OK', 'ceph'],
        'host3':['OK', 'FAILED', 'FAILED', 'UNKNOWN', 'FAILED', 'netapp'],
        'host4':['OK', 'OK', 'FAILED', 'UNKNOWN', 'OK', 'netapp'],
        'host5':['OK', 'OK', 'OK', 'UNKNOWN', 'OK', 'ceph'],
    }
    """
    if CONF.account_for_az:
        return _filter_hosts_by_az(hosts_statics, threshold)
    else:
        return _filter_hosts_by_region(hosts_statics, threshold)
