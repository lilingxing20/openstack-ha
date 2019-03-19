# coding=utf-8

"""Host HA inspectors"""
from nova_compute_agent import constant
from nova_compute_agent.openstack.common import log as logging
LOG = logging.getLogger(__name__)

class BaseInspector(object):
    """Base class for Host HA Inspector."""

    def _is_ok(self, host):
        """ return True if host passed the inspector.
        """
        raise NotImplementedError()

    def check(self, host):
        """check host's health , then return 'OK', 'FAILED' or 'UNKNOWN'.
        this can be overridden by subclass.
        """
        try:
            if self._is_ok(host) is False:
                return constant.FAILED
            return constant.OK
        except Exception as e:
            LOG.warning(e)
            return constant.UNKNOWN
