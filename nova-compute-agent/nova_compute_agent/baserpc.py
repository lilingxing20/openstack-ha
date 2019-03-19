# coding=utf-8

"""
Base RPC client and server common to all services.
"""
try:
    from oslo.config import cfg
except ImportError:
    from oslo_config import cfg

try:
    from oslo import messaging
except ImportError:
    import oslo_messaging as messaging

from nova_compute_agent.openstack.common import jsonutils
from nova_compute_agent import rpc
_NAMESPACE = 'baseapi'

class BaseAPI(object):
    """Client side of the base rpc API.
    
    API version history:
    
        1.0 - Initial version.
    """

    def __init__(self, topic):
        super(BaseAPI, self).__init__()
        target = messaging.Target(topic=topic, namespace=_NAMESPACE, version='1.0')
        self.client = rpc.get_client(target)

    def ping(self, context, arg, timeout=None):
        arg_p = jsonutils.to_primitive(arg)
        cctxt = self.client.prepare(timeout=timeout)
        return cctxt.call(context, 'ping', arg=arg_p)


class BaseRPCAPI(object):
    """Server side of the base RPC API."""
    target = messaging.Target(namespace=_NAMESPACE, version='1.1')

    def __init__(self, service_name):
        self.service_name = service_name

    def ping(self, context, arg):
        resp = {'service': self.service_name + '_rpc_test','arg': arg}
        return jsonutils.to_primitive(resp)
