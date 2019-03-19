# coding=utf-8

""" Inspector through Ping """
import os
import subprocess
try:
    from oslo.config import cfg
except ImportError:
    from oslo_config import cfg

from nova_compute_agent import constant
from nova_compute_agent import inspect
from nova_compute_agent.openstack.common import log as logging
CONF = cfg.CONF
LOG = logging.getLogger(__name__)
ping_opts = [
 cfg.IntOpt('packet_count', default=5, help='Stop after sending count ECHO_REQUEST packets.'),
 cfg.IntOpt('packet_interval', default=1, help='Interval between packets.'),
 cfg.StrOpt('ping_list_file_path', default='/etc/nova-compute-agent/ping-list.conf', help='File name of host IP info for the ping inspector.'),
 cfg.ListOpt('ip_item_format', default='MANAGEMENT_IP,CEPH_PUBLIC_IP', help='Specifies the format of the item in the ping_list_file_path file.')]
CONF.register_opts(ping_opts, 'ping')

class PingInspector(inspect.BaseInspector):
    """Ping inspector."""

    def __init__(self):
        self.count = CONF.ping.packet_count
        self.packet_interval = CONF.ping.packet_interval
        self.ip_names = CONF.ping.ip_item_format
        self._validate_ip_names(self.ip_names)
        self.ip_num = len(self.ip_names)
        self.hosts_info = self._load_ping_list_conf()
        super(PingInspector, self).__init__()

    def _validate_ip_names(self, ip_names):
        for name in ip_names:
            if name not in constant.IP_TYPES:
                msg = 'Invalid IP name found in the configuration ip_item_format.'
                LOG.error(msg)
                raise Exception(msg)

    def _load_ping_list_conf(self):
        """Load host IPMI access information from conf file."""
        hosts_info = {}
        file_path = CONF.ping.ping_list_file_path
        if not os.path.exists(file_path):
            msg = 'Must provide ping.ping_list_file_path'
            LOG.error(msg)
            raise Exception(msg)
        with open(file_path) as f:
            for num, line in enumerate(f):
                line = line.strip()
                if line.startswith('#') or len(line) == 0:
                    continue
                host_name, ip_info = line.split('=', 1)
                ips = ip_info.split(',')
                ips = [ ip.strip() for ip in ips ]
                if not len(ips) == self.ip_num:
                    msg = 'Wrong at line %d in ping_list_file_path. There suppose to be %d IPs, but %d IPs found' % (
                     num, self.ip_num, len(ips))
                    LOG.error(msg)
                    raise Exception(msg)
                hosts_info[host_name] = dict(zip(self.ip_names, ips))

        return hosts_info

    def check(self, host):
        LOG.info('PingInspector: inspect %s', host)
        ping_result = {}
        if len(self.hosts_info) == 0:
            LOG.warning("Can't get ping information from file %s" % CONF.ping.ping_list_file_path)
            return ping_result
        if host not in self.hosts_info:
            LOG.warning("Can't get %s information from file %s, please check the file." % (
             host, CONF.ping.ping_list_file_path))
            return ping_result
        for ip_name in self.hosts_info[host]:
            ping_result[ip_name] = self._is_ping_ok(self.hosts_info[host][ip_name])

        return ping_result

    def _is_ping_ok(self, ip):
        redirect = '' if CONF.debug else '> /dev/null'
        cmd = 'ping -c %d -i %d %s %s 2>&1' % (
         self.count, self.packet_interval, ip, redirect)
        try:
            ret = subprocess.call(cmd, shell=True)
            if ret == 0:
                return constant.OK
            LOG.warning('Ping command: %s returns %d' % (cmd, ret))
            return constant.FAILED
        except Exception as e:
            LOG.warning(e)
            return constant.UNKNOWN
