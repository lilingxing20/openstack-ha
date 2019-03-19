# coding=utf-8

__all__ = [
 'init',
 'cleanup',
 'set_defaults',
 'add_extra_exmods',
 'clear_extra_exmods',
 'get_allowed_exmods',
 'RequestContextSerializer',
 'get_client',
 'get_server',
 'get_notifier',
 'TRANSPORT_ALIASES']
try:
    from oslo.config import cfg
except ImportError:
    from oslo_config import cfg

try:
    from oslo import messaging
except ImportError:
    import oslo_messaging as messaging

from nova_compute_agent.openstack.common import jsonutils
CONF = cfg.CONF
TRANSPORT = None
NOTIFIER = None
ALLOWED_EXMODS = []
EXTRA_EXMODS = []

def init(conf):
    global NOTIFIER
    global TRANSPORT
    exmods = get_allowed_exmods()
    messaging.set_transport_defaults(control_exchange='nova_compute_agent')
    TRANSPORT = messaging.get_transport(conf, allowed_remote_exmods=exmods)
    serializer = RequestContextSerializer(JsonPayloadSerializer())
    NOTIFIER = messaging.Notifier(TRANSPORT, serializer=serializer)


def cleanup():
    global TRANSPORT
    global NOTIFIER
    assert TRANSPORT is not None
    assert NOTIFIER is not None
    TRANSPORT.cleanup()
    TRANSPORT = NOTIFIER = None
    return


def set_defaults(control_exchange):
    messaging.set_transport_defaults(control_exchange)


def add_extra_exmods(*args):
    EXTRA_EXMODS.extend(args)


def clear_extra_exmods():
    del EXTRA_EXMODS[:]


def get_allowed_exmods():
    return ALLOWED_EXMODS + EXTRA_EXMODS


class JsonPayloadSerializer(messaging.NoOpSerializer):

    @staticmethod
    def serialize_entity(context, entity):
        return jsonutils.to_primitive(entity, convert_instances=True)


class RequestContextSerializer(messaging.Serializer):

    def __init__(self, base):
        self._base = base

    def serialize_entity(self, context, entity):
        if not self._base:
            return entity
        return self._base.serialize_entity(context, entity)

    def deserialize_entity(self, context, entity):
        if not self._base:
            return entity
        return self._base.deserialize_entity(context, entity)

    def serialize_context(self, context):
        return context

    def deserialize_context(self, context):
        return context


def get_transport_url(url_str=None):
    return messaging.TransportURL.parse(CONF, url_str, TRANSPORT_ALIASES)


def get_client(target, version_cap=None, serializer=None):
    assert TRANSPORT is not None
    serializer = RequestContextSerializer(serializer)
    return messaging.RPCClient(TRANSPORT, target, version_cap=version_cap, serializer=serializer)


def get_server(target, endpoints, serializer=None):
    assert TRANSPORT is not None
    serializer = RequestContextSerializer(serializer)
    return messaging.get_rpc_server(TRANSPORT, target, endpoints, executor='eventlet', serializer=serializer)


def get_notifier(service=None, host=None, publisher_id=None):
    assert NOTIFIER is not None
    if not publisher_id:
        publisher_id = '%s.%s' % (service, host or CONF.host)
    return NOTIFIER.prepare(publisher_id=publisher_id)
