# coding=utf-8

from nova_compute_agent import handle
from nova_compute_agent.openstack.common import log as logging
from nova_compute_agent import utils
LOG = logging.getLogger(__name__)

class EvacuateHandler(handle.BaseHandler):
    """Evacute handler.
     Evacuate instances on fault host to other available hosts
    """

    def handle_host(self, host):
        """ Handle single host with fault.
        """
        LOG.info('EvacuateHandler: handle host %s' % host)
        utils.list_instances(host=host)
        response = utils.do_host_evacuate(host=host)
        self.handle_response(response)
        utils.list_instances(host=host)
        return True

    def handle_response(self, response):
        """Handle evacuate response."""
        for resp in response:
            if resp.evacuate_accepted:
                LOG.info('evacuate %s is accepted' % resp.server_uuid)
            else:
                LOG.info('evacuate %s failed: %s' % (resp.server_uuid,
                 resp.error_message))
