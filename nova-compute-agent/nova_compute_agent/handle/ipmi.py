# coding=utf-8

from nova_compute_agent import handle
from nova_compute_agent.inspect import ipmi
from nova_compute_agent.openstack.common import log as logging
LOG = logging.getLogger(__name__)

class IPMIPowerOffHandler(handle.BaseHandler):
    """IPMI Power off handler.
     Power off fault host by IPMI.
    """

    def __init__(self):
        self.ipmi = ipmi.IPMIInspector()

    def handle_host(self, host):
        """ Handle single host with fault.
        """
        LOG.info('IPMIPoweroffHandler: handle host %s' % host)
        cmd = 'chassis power off'
        data = self.ipmi._query_ipmi(host, cmd)
        if data == '':
            raise Exception("can't power off host: %s" % host)
