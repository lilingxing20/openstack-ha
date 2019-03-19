# coding=utf-8

""" Inspector through Nic """
import shlex
import subprocess
try:
    from oslo.config import cfg
except ImportError:
    from oslo_config import cfg

from nova_compute_agent import inspect
from nova_compute_agent.openstack.common import log as logging
CONF = cfg.CONF
LOG = logging.getLogger(__name__)
nic_opts = [
 cfg.StrOpt('product_bridge_name', default='br-prv', help='bridge name which instances connect to'),
 cfg.ListOpt('physical_nic_prefixes', default=[
  'eth', 'en'], help='The prefixes which physical NIC name start with.'),
 cfg.IntOpt('ssh_timeout', default=10, help='Timeout for ssh operations.')]
CONF.register_opts(nic_opts)

class NicInspector(inspect.BaseInspector):
    """Nic inspector."""

    def __init__(self):
        self.product_bridge_name = CONF.product_bridge_name
        super(NicInspector, self).__init__()

    def _is_ok(self, host):
        LOG.info('NicInspector: inspect %s', host)
        host = str(host)
        nics = self._find_prv_nics(host)
        for nic in nics:
            if self._is_prv_nic_up(host, nic):
                return True

        return False

    def _is_physical_nic(self, iface):
        if iface != '' and '-' not in iface:
            for prefix in CONF.physical_nic_prefixes:
                if iface.startswith(prefix):
                    return True

        return False

    def _find_prv_nics(self, host):
        nics = []
        cmd = 'ssh -o ConnectTimeout=%s %s "ovs-vsctl list-ports %s"|grep %s--br-' % (
         CONF.ssh_timeout, host,
         self.product_bridge_name,
         self.product_bridge_name)
        shell_cmd = shlex.split(cmd)
        ret = subprocess.Popen(shell_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout = ret.communicate()[0]
        LOG.debug('Get peer bridge with command: %s output: %s', cmd, stdout)
        bridge_seperator = self.product_bridge_name + '--'
        bridge = stdout.split('\n')[0].split(bridge_seperator)[1]
        cmd = 'ssh -o ConnectTimeout=%s %s "ovs-vsctl list-ifaces %s"' % (
         CONF.ssh_timeout, host, bridge)
        shell_cmd = shlex.split(cmd)
        ret = subprocess.Popen(shell_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout = ret.communicate()[0]
        LOG.debug('Get interfaces with command: %s output: %s', cmd, stdout)
        for iface in stdout.split('\n'):
            if self._is_physical_nic(iface):
                nics.append(iface)

        LOG.debug('Got nics: %s', nics)
        if len(nics) == 0:
            msg = 'Can not get %s private nics cmd:%s output: %s' % (
             host, cmd, stdout)
            LOG.warning(msg)
            raise Exception(msg)
        return nics

    def _is_prv_nic_up(self, host, nic):
        cmd = 'ssh -o ConnectTimeout=%s %s "cat /sys/class/net/%s/operstate"' % (
         CONF.ssh_timeout, host, nic)
        args = shlex.split(cmd)
        ret = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout = ret.communicate()[0]
        LOG.debug('Get interface state command: %s output: %s', cmd, stdout)
        state = stdout.strip()
        if state == 'down' or state == 'lowerlayerdown':
            LOG.warning('check %s nic %s is down output: %s', host, nic, stdout)
            return False
        else:
            return True
