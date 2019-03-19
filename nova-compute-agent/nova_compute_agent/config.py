# coding=utf-8

try:
    from oslo.config import cfg
except ImportError:
    from oslo_config import cfg

from nova_compute_agent import rpc
CONF = cfg.CONF

def parse_args(argv, default_config_files=None):
    rpc.set_defaults(control_exchange='nova_compute_agent')
    CONF(argv[1:], project='nova_compute_agent', version='0.1', default_config_files=default_config_files)
    rpc.init(CONF)
