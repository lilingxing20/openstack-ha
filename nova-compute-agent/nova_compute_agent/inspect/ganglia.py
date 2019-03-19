# coding=utf-8

""" Inspector through ganglia service """
import telnetlib
import time
try:
    from oslo.config import cfg
except ImportError:
    from oslo_config import cfg

from nova_compute_agent import inspect
from nova_compute_agent.openstack.common import log as logging
section_prefix = '<HOST'
CONF = cfg.CONF
LOG = logging.getLogger(__name__)
ganglia_opts = [
 cfg.IntOpt('max_reported_interval', default=30, help='Host will be judged as down when its host reported time exceed this value.'),
 cfg.StrOpt('gmetad_host', default='127.0.0.1', help="gmetad service's host"),
 cfg.IntOpt('gmetad_port', default=8651, help="gmetad service' port.")]
CONF.register_opts(ganglia_opts, 'ganglia')

class GangliaInspector(inspect.BaseInspector):
    """Ganglia inspector."""

    def __init__(self):
        self.host = CONF.ganglia.gmetad_host
        self.port = CONF.ganglia.gmetad_port
        self.host_update_map = {}
        self.current_time = long(time.time())
        super(GangliaInspector, self).__init__()

    def _query_ganglia_data(self):
        """telnet gmetad and get data."""
        self.current_time = long(time.time())
        tn = telnetlib.Telnet(self.host, self.port)
        output = tn.read_all()
        tn.close()
        return output

    def _parse_ganglia_data(self, output):
        """Parse ganglia data
        output like:
        <HOST NAME="node-1.domain.tld" IP="192.168.0.3" REPORTED="1418201749"
        """
        for line in output.split('\n'):
            if line.startswith(section_prefix):
                attributes = line.split(' ')
                host_name = attributes[1][len('NAME='):].strip('"')
                reported_time = attributes[3][len('REPORTED='):].strip('"')
                self.host_update_map[host_name] = long(reported_time)

    def _has_fault(self, host):
        LOG.info('GangliaInspector: inspect %s', host)
        if host not in self.host_update_map:
            return True
        time_delta = self.current_time - self.host_update_map[host]
        return time_delta > CONF.ganglia.max_reported_interval

    def check(self, hosts):
        fault_hosts = []
        output = self._query_ganglia_data()
        self._parse_ganglia_data(output)
        for host in hosts:
            if self._has_fault(host):
                fault_hosts.append(host)

        return fault_hosts

    def query_host_update_map(self):
        output = self._query_ganglia_data()
        self._parse_ganglia_data(output)
        return self.host_update_map
