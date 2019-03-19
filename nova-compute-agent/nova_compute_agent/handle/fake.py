# coding=utf-8

from nova_compute_agent import handle
from nova_compute_agent.openstack.common import log as logging
LOG = logging.getLogger(__name__)

class FakeHandler(handle.BaseHandler):
    """Fake handler."""

    def handle_host(self, host):
        """ Handle single host with fault.
        """
        LOG.info('FakeHandler: handle host %s' % host)
