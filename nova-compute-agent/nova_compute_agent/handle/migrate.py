# coding=utf-8

from nova_compute_agent import handle
from nova_compute_agent.openstack.common import log as logging
from nova_compute_agent import utils
LOG = logging.getLogger(__name__)

class MigrateHandler(handle.BaseHandler):
    """Migrate handler.
     Migrate instances on warn host to other available hosts
    """

    def handle_host(self, host, ignore_hosts=[]):
        """ Handle single host with fault.
        """
        LOG.info('MigrateHandler: handle host %s' % host)
        utils.list_instances(host=host)
        response = utils.do_host_migrate(host=host)
        self.handle_response(response)
        utils.list_instances(host=host)

    def handle_response(self, response):
        """Handle migration response."""
        for resp in response:
            if resp.migrate_accepted:
                LOG.info('Migrate %s accepted successfully' % resp.server_uuid)
            else:
                LOG.info('Migrate %s failed: %s' % (resp.server_uuid,
                 resp.error_message))
