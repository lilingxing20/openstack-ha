# coding=utf-8

"""Inspector through IPMI"""
import contextlib
import os
import stat
import tempfile
import time
try:
    from oslo.config import cfg
except ImportError:
    from oslo_config import cfg

from nova_compute_agent import inspect
from nova_compute_agent.openstack.common import log as logging
from nova_compute_agent.openstack.common import processutils
from nova_compute_agent import utils
CONF = cfg.CONF
LOG = logging.getLogger(__name__)
opts = [
 cfg.StrOpt('separator', default=' ', help='The separator used in ipmi.conf'),
 cfg.IntOpt('retry_timeout', default=60, help='Maximum time in seconds to retry IPMI operations.'),
 cfg.IntOpt('min_command_interval', default=5, help='Minimum time, in seconds, between IPMI operations sent to a server. There is a risk with some hardware that setting this too low may cause the BMC to crash. Recommended setting is 5 seconds.'),
 cfg.StrOpt('conf_file_path', default='/etc/nova-compute-agent/ipmi.conf', help='File name of host IPMI access info.')]
CONF.register_opts(opts, group='ipmi')
VALID_PRIV_LEVELS = [
 'ADMINISTRATOR', 'CALLBACK', 'OPERATOR', 'USER']
LAST_CMD_TIME = {}
TIMING_SUPPORT = None
SINGLE_BRIDGE_SUPPORT = None
DUAL_BRIDGE_SUPPORT = None
ipmitool_command_options = {'timing': [
            'ipmitool', '-N', '0', '-R', '0', '-h'],
   'single_bridge': [
                   'ipmitool', '-m', '0', '-b', '0', '-t', '0', '-h'],
   'dual_bridge': [
                 'ipmitool', '-m', '0', '-b', '0', '-t', '0',
                 '-B', '0', '-T', '0', '-h']
   }

def _check_option_support(options):
    """Checks if the specific ipmitool options are supported on host.
    
    This method updates the module-level variables indicating whether
    an option is supported so that it is accessible by any driver
    interface class in this module. It is intended to be called from
    the __init__ method of such classes only.
    
    :param options: list of ipmitool options to be checked
    :raises: OSError
    """
    for opt in options:
        if _is_option_supported(opt) is None:
            try:
                cmd = ipmitool_command_options[opt]
                out, err = utils.execute(*cmd)
            except processutils.ProcessExecutionError:
                _is_option_supported(opt, False)
            else:
                _is_option_supported(opt, True)

    return


def _is_option_supported(option, is_supported=None):
    """Indicates whether the particular ipmitool option is supported.
    
    :param option: specific ipmitool option
    :param is_supported: Optional Boolean. when specified, this value
                         is assigned to the module-level variable indicating
                         whether the option is supported. Used only if a value
                         is not already assigned.
    :returns: True, indicates the option is supported
    :returns: False, indicates the option is not supported
    :returns: None, indicates that it is not aware whether the option
              is supported
    """
    global TIMING_SUPPORT
    global SINGLE_BRIDGE_SUPPORT
    global DUAL_BRIDGE_SUPPORT
    if option == 'single_bridge':
        if SINGLE_BRIDGE_SUPPORT is None and is_supported is not None:
            SINGLE_BRIDGE_SUPPORT = is_supported
        return SINGLE_BRIDGE_SUPPORT
    else:
        if option == 'dual_bridge':
            if DUAL_BRIDGE_SUPPORT is None and is_supported is not None:
                DUAL_BRIDGE_SUPPORT = is_supported
            return DUAL_BRIDGE_SUPPORT
        if option == 'timing':
            if TIMING_SUPPORT is None and is_supported is not None:
                TIMING_SUPPORT = is_supported
            return TIMING_SUPPORT
        return


@contextlib.contextmanager
def _make_password_file(password):
    """Makes a temporary file that contains the password.
    
    :param password: the password
    :returns: the absolute pathname of the temporary file
    :raises: PasswordFileFailedToCreate from creating or writing to the
             temporary file
    """
    try:
        fd, path = tempfile.mkstemp()
        os.fchmod(fd, stat.S_IRUSR | stat.S_IWUSR)
        with os.fdopen(fd, 'w') as f:
            f.write(password)
        yield path
        utils.delete_if_exists(path)
    except Exception as exc:
        with excutils.save_and_reraise_exception():
            utils.delete_if_exists(path)


def _exec_ipmitool(node_info, command, use_timing=False):
    """Execute the ipmitool command.
    
    This uses the lanplus interface to communicate with the BMC device driver.
    
    :param node_info: the ipmitool parameters for accessing a node.
    :param command: the ipmitool command to be executed.
    :returns: (stdout, stderr) from executing the command.
    :raises: PasswordFileFailedToCreate from creating or writing to the
             temporary file.
    :raises: processutils.ProcessExecutionError from executing the command.
    
    """
    args = [
     'ipmitool',
     '-I',
     'lanplus',
     '-H',
     node_info['address'],
     '-L', node_info.get('priv_level', VALID_PRIV_LEVELS[0])]
    if node_info['username']:
        args.append('-U')
        args.append(node_info['username'])
    if use_timing and _is_option_supported('timing'):
        num_tries = max(CONF.ipmi.retry_timeout // CONF.ipmi.min_command_interval, 1)
        args.append('-R')
        args.append(str(num_tries))
        args.append('-N')
        args.append(str(CONF.ipmi.min_command_interval))
    with _make_password_file(node_info['password'] or '\x00') as pw_file:
        args.append('-f')
        args.append(pw_file)
        args.extend(command.split(' '))
        time_till_next_poll = CONF.ipmi.min_command_interval - (time.time() - LAST_CMD_TIME.get(node_info['address'], 0))
        if time_till_next_poll > 0:
            time.sleep(time_till_next_poll)
        try:
            try:
                out, err = utils.execute(*args)
            except processutils.ProcessExecutionError as e:
                LOG.error('IPMI Error: %s', e)
                return (
                 '', str(e))

        finally:
            LAST_CMD_TIME[node_info['address']] = time.time()

        return (out, err)


class IPMIInspector(inspect.BaseInspector):
    """IPMI inspector."""

    def __init__(self):
        self.ipmi_infos = self._load_ipmi_conf()
        try:
            _check_option_support(['timing', 'single_bridge', 'dual_bridge'])
        except OSError:
            raise Exception('Unable to locate usable ipmitool command in the system path when checking ipmitool version')

        super(IPMIInspector, self).__init__()

    def _load_ipmi_conf(self):
        """Load host IPMI access information from conf file."""
        ipmi_infos = {}
        file_path = CONF.ipmi.conf_file_path
        if not os.path.exists(file_path):
            raise Exception('Must provide ipmi.conf_file_path')
        with open(file_path) as f:
            for line in f.readlines():
                line = line.strip()
                if line.startswith('#') or len(line) == 0:
                    continue
                host_name, access_info = line.split('=', 1)
                separator = CONF.ipmi.separator
                address, username, password = access_info.split(separator)
                ipmi_infos[host_name] = dict(address=address, username=username, password=password)

        return ipmi_infos

    def _is_ok(self, host):
        """ return True if host with power on.
        """
        LOG.info('IPMIInspector: inspect %s', host)
        return self._is_power_on(host)

    def _query_ipmi(self, host, cmd):
        if host not in self.ipmi_infos:
            LOG.warn('%s: do not have IPMI access info, just skip.' % host)
            return ''
        else:
            node_info = self.ipmi_infos[host]
            out, err = _exec_ipmitool(node_info, cmd)
            if err == '':
                return out
            LOG.warn('%s: ipmitool returns with error, just skip.' % host)
            return ''

    def _is_power_on(self, host):
        """Get chassis power status.
        ipmitool> chassis power status
        Chassis Power is on/off
        """
        cmd = 'chassis power status'
        data = self._query_ipmi(host, cmd)
        if data == '':
            raise Exception("can't get power status")
        for line in data.strip().split('\n'):
            if line.startswith('Chassis Power is on'):
                return True

        return False
