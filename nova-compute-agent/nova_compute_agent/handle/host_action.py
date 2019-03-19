# coding=utf-8

import time
from nova_compute_agent import handle
from nova_compute_agent.openstack.common import log as logging
from nova_compute_agent import utils
LOG = logging.getLogger(__name__)
ACTION_RECORDS = {}
MAX_RETRY = {}
SERVICE_DELAY = 600
NODE_DELAY = 1800
RETRY = 2

class CephNoOutHandler(handle.BaseHandler):
    """ set ceph osd noout."""

    def _handle_host(self, host):
        cmd = [
         'ceph', 'osd', 'set', 'noout']
        LOG.info('CephNoOutHandler: handle host %s' % host)
        result = utils.execute(*cmd)
        LOG.info('handle host %s result: %s' % (host, result))


class RestartComputeServiceHandler(handle.BaseHandler):
    """ Restart compute service."""

    def _handle_host(self, host):
        cmd = [
         'ssh', host, 'service', 'openstack-nova-compute', 'restart']
        LOG.info('RestartComputeServiceHandler: handle host %s' % host)
        if exceed_retry(host) or action_too_soon(host, 'restart_service', SERVICE_DELAY):
            return
        set_action_record(host, 'restart_service')
        result = utils.execute(*cmd)
        LOG.info('handle host %s result: %s' % (host, result))


class StartComputeServiceHandler(handle.BaseHandler):
    """ Start compute service."""

    def _handle_host(self, host):
        cmd = [
         'ssh', host, 'service', 'openstack-nova-compute', 'start']
        LOG.info('StartComputeServiceHandler: handle host %s' % host)
        if exceed_retry(host) or action_too_soon(host, 'start_service', SERVICE_DELAY):
            return
        set_action_record(host, 'start_service')
        result = utils.execute(*cmd)
        LOG.info('handle host %s result: %s' % (host, result))


class StopComputeServiceHandler(handle.BaseHandler):
    """ Stop compute service."""

    def _handle_host(self, host):
        cmd = [
         'ssh', host, 'service', 'openstack-nova-compute', 'stop']
        LOG.info('StopComputeServiceHandler: handle host %s' % host)
        if exceed_retry(host) or action_too_soon(host, 'stop_service', SERVICE_DELAY):
            return
        set_action_record(host, 'stop_service')
        result = utils.execute(*cmd)
        LOG.info('handle host %s result: %s' % (host, result))


class ShutdownComputeNodeHandler(handle.BaseHandler):
    """ Shutdown compute node."""

    def _handle_host(self, host):
        cmd = [
         'ssh', host, 'shutdown', 'now']
        LOG.info('ShutdownComputeNodeHandler: handle host %s' % host)
        if exceed_retry(host) or action_too_soon(host, 'shutdown_node', NODE_DELAY):
            return
        set_action_record(host, 'shutdown_node')
        result = utils.execute(*cmd)
        LOG.info('handle host %s result: %s' % (host, result))


class RebootComputeNodeHandler(handle.BaseHandler):
    """ Reboot compute node."""

    def _handle_host(self, host):
        cmd = [
         'ssh', host, 'reboot']
        LOG.info('RebootComputeNodeHandler: handle host %s' % host)
        if exceed_retry(host) or action_too_soon(host, 'reboot_node', NODE_DELAY):
            return
        set_action_record(host, 'reboot_node')
        result = utils.execute(*cmd)
        LOG.info('handle host %s result: %s' % (host, result))


def get_action_record(host, action):
    """ get specific host action record """
    record = ACTION_RECORDS.get(host)
    if record is None:
        ACTION_RECORDS[host] = {}
        ACTION_RECORDS[host][action] = 0
        record = ACTION_RECORDS.get(host)
    if action not in record.keys():
        ACTION_RECORDS[host][action] = 0
    return ACTION_RECORDS[host][action]


def set_action_record(host, action):
    """ get specific host action record """
    record = ACTION_RECORDS.get(host)
    if record is None:
        ACTION_RECORDS[host] = {}
        ACTION_RECORDS[host][action] = time.time()
    else:
        ACTION_RECORDS[host][action] = time.time()
    if MAX_RETRY.get(host) is None:
        MAX_RETRY[host] = 1
    else:
        MAX_RETRY[host] = MAX_RETRY[host] + 1
    return


def exceed_retry(host):
    if host in MAX_RETRY and MAX_RETRY[host] >= RETRY:
        LOG.info('Exceed max retry: %s , skip the action.' % host)
        return True
    else:
        return False


def action_too_soon(host, action, interval):
    last_time = get_action_record(host, action)
    now = time.time()
    if now - last_time < interval:
        LOG.info('action too soon: %s , skip the action.' % host)
        return True
    else:
        return False
