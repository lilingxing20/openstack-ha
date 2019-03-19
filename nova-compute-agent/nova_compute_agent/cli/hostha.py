# coding=utf-8

"""Starter script for Nova Compute HA agent."""

import sys
import traceback
import eventlet
try:
    from oslo.config import cfg
except ImportError:
    from oslo_config import cfg

from nova_compute_agent.openstack.common import log as logging
from nova_compute_agent import service
from nova_compute_agent import config


nova_compute_agent_opts = [
 cfg.StrOpt('nova_compute_agent_topic', default='nova_compute_agent', help='The topic nova_compute_agent listen on')]
CONF = cfg.CONF
CONF.register_opts(nova_compute_agent_opts)


def main():
    config.parse_args(sys.argv)
    logging.setup('nova_compute_agent')
    eventlet.monkey_patch()
    server = service.Service.create(binary='nova-compute-agent', topic=CONF.nova_compute_agent_topic)
    service.serve(server)
    service.wait()
