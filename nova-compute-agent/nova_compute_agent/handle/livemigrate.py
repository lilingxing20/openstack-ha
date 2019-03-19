# coding=utf-8

from nova_compute_agent import handle
from nova_compute_agent.openstack.common import log as logging
from nova_compute_agent import utils
LOG = logging.getLogger(__name__)

class LiveMigrateHandler(handle.BaseHandler):
    """Live migration handler.
     Live migration instances on warn host to other available hosts
    """

    def handle_host(self, host, ignore_hosts=[]):
        """ Handle single host with fault.
        """
        LOG.info('LiveMigrateHandler: handle host %s' % host)
        response = utils.do_host_evacuate_live(host=host, ignore_hosts=ignore_hosts)
        self.handle_response(response)

    def handle_response(self, response):
        """Handle live migration response."""
        for resp in response:
            if resp.live_migration_accepted:
                LOG.info('live migrate %s successfully' % resp.server_uuid)
            else:
                LOG.info('live migrate %s failed: %s' % (resp.server_uuid,
                 resp.error_message))
