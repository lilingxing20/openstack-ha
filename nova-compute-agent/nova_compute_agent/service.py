# coding=utf-8

"""Generic Node base class for all workers that run on hosts."""
import os
import sys
try:
    from oslo.config import cfg
except ImportError:
    from oslo_config import cfg

try:
    from oslo import messaging
except ImportError:
    import oslo_messaging as messaging

from nova_compute_agent import baserpc
from nova_compute_agent import rpc
from nova_compute_agent.openstack.common.gettextutils import _
from nova_compute_agent.openstack.common import importutils
from nova_compute_agent.openstack.common import log as logging
from nova_compute_agent.openstack.common import processutils
from nova_compute_agent.openstack.common import service
LOG = logging.getLogger(__name__)
service_opts = [
 cfg.StrOpt('nova_compute_agent_manager', default='nova_compute_agent.agent.manager.HostHAManager', help='Full class name for the Manager for nova-compute-agent'),
 cfg.StrOpt('host', default='nova_compute_agent-host1', help='Host name for the Manager for nova_compute_agent'),
 cfg.BoolOpt('use_rpc', default=False, help='Use RPC messaging or not.')]
CONF = cfg.CONF
CONF.register_opts(service_opts)

class Service(service.Service):
    """Service object for binaries running on hosts.
    
    A service takes a manager and enables rpc by listening to queues based
    on topic. It also periodically runs tasks on the manager and reports
    it state to the database services table.
    """

    def __init__(self, host, binary, topic, manager, *args, **kwargs):
        super(Service, self).__init__()
        self.host = host
        self.binary = binary
        self.topic = topic
        self.manager_class_name = manager
        manager_class = importutils.import_class(self.manager_class_name)
        self.manager = manager_class(host=self.host, *args, **kwargs)
        self.rpcserver = None
        self.saved_args, self.saved_kwargs = args, kwargs
        return

    def start(self):
        if CONF.use_rpc:
            LOG.audit(_('Starting %(topic)s node (version %(version)s)'), {'topic': self.topic,'version': '0.1'})
            LOG.debug('Creating RPC server for service %s', self.topic)
            target = messaging.Target(topic=self.topic, server=self.host)
            endpoints = [
             self.manager,
             baserpc.BaseRPCAPI('nova_compute_agent')]
            self.rpcserver = rpc.get_server(target, endpoints)
            self.rpcserver.start()
        self.tg.add_dynamic_timer(self.periodic_tasks, initial_delay=None, periodic_interval_max=30)
        LOG.debug('Started service %s', self.topic)
        return

    def __getattr__(self, key):
        manager = self.__dict__.get('manager', None)
        return getattr(manager, key)

    @classmethod
    def create(cls, host=None, binary=None, topic=None, manager=None):
        """Instantiates class and passes back application object.
        
        :param host: defaults to CONF.host
        :param binary: defaults to basename of executable
        :param topic: defaults to bin_name - 'nova-' part
        :param manager: defaults to CONF.<topic>_manager
        
        """
        if not host:
            host = CONF.host
        if not binary:
            binary = os.path.basename(sys.argv[0])
        if not topic:
            topic = 'nova_compute_agent'
        if not manager:
            # manager_cls = '%s_manager' % binary.rpartition('nova-cmopute-agent')[2]
            manager_cls = 'nova_compute_agent_manager'
            manager = CONF.get(manager_cls, None)
        service_obj = cls(host, binary, topic, manager)
        return service_obj

    def kill(self):
        """Destroy the service object in the datastore."""
        self.stop()

    def stop(self):
        if CONF.use_rpc:
            try:
                self.rpcserver.stop()
                self.rpcserver.wait()
            except Exception:
                pass

        try:
            self.manager.cleanup_host()
        except Exception:
            LOG.exception(_('Service error occurred during cleanup_host'))

        super(Service, self).stop()

    def periodic_tasks(self, raise_on_error=False):
        """Tasks to be run at a periodic interval."""
        return self.manager.periodic_tasks({'context': 'name'}, raise_on_error=raise_on_error)


def process_launcher():
    return service.ProcessLauncher()


_launcher = None

def serve(server, workers=None):
    global _launcher
    if _launcher:
        raise RuntimeError(_('serve() can only be called once'))
    _launcher = service.launch(server, workers=workers)


def wait():
    _launcher.wait()
