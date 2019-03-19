# coding=utf-8

import datetime
import time
try:
    from oslo.config import cfg
except ImportError:
    from oslo_config import cfg

import six
from nova_compute_agent.openstack.common.gettextutils import _
from nova_compute_agent.openstack.common import log as logging
from nova_compute_agent.openstack.common import timeutils
periodic_opts = [
 cfg.BoolOpt('run_external_periodic_tasks', default=True, help='Some periodic tasks can be run in a separate process. Should we run them here?')]
CONF = cfg.CONF
CONF.register_opts(periodic_opts)
LOG = logging.getLogger(__name__)
DEFAULT_INTERVAL = 60.0

class InvalidPeriodicTaskArg(Exception):
    message = _('Unexpected argument for periodic task creation: %(arg)s.')


def periodic_task(*args, **kwargs):
    """Decorator to indicate that a method is a periodic task.
    
    This decorator can be used in two ways:
    
        1. Without arguments '@periodic_task', this will be run on every cycle
           of the periodic scheduler.
    
        2. With arguments:
           @periodic_task(spacing=N [, run_immediately=[True|False]])
           this will be run on approximately every N seconds. If this number is
           negative the periodic task will be disabled. If the run_immediately
           argument is provided and has a value of 'True', the first run of the
           task will be shortly after task scheduler starts.  If
           run_immediately is omitted or set to 'False', the first time the
           task runs will be approximately N seconds after the task scheduler
           starts.
    """

    def decorator(f):
        if 'ticks_between_runs' in kwargs:
            raise InvalidPeriodicTaskArg(arg='ticks_between_runs')
        f._periodic_task = True
        f._periodic_external_ok = kwargs.pop('external_process_ok', False)
        if f._periodic_external_ok and not CONF.run_external_periodic_tasks:
            f._periodic_enabled = False
        else:
            f._periodic_enabled = kwargs.pop('enabled', True)
        f._periodic_spacing = kwargs.pop('spacing', 0)
        f._periodic_immediate = kwargs.pop('run_immediately', False)
        if f._periodic_immediate:
            f._periodic_last_run = None
        else:
            f._periodic_last_run = timeutils.utcnow()
        return f

    if kwargs:
        return decorator
    else:
        return decorator(args[0])


class _PeriodicTasksMeta(type):

    def __init__(cls, names, bases, dict_):
        """Metaclass that allows us to collect decorated periodic tasks."""
        super(_PeriodicTasksMeta, cls).__init__(names, bases, dict_)
        try:
            cls._periodic_tasks = cls._periodic_tasks[:]
        except AttributeError:
            cls._periodic_tasks = []

        try:
            cls._periodic_last_run = cls._periodic_last_run.copy()
        except AttributeError:
            cls._periodic_last_run = {}

        try:
            cls._periodic_spacing = cls._periodic_spacing.copy()
        except AttributeError:
            cls._periodic_spacing = {}

        for value in cls.__dict__.values():
            if getattr(value, '_periodic_task', False):
                task = value
                name = task.__name__
                if task._periodic_spacing < 0:
                    LOG.info(_('Skipping periodic task %(task)s because its interval is negative'), {'task': name})
                    continue
                if not task._periodic_enabled:
                    LOG.info(_('Skipping periodic task %(task)s because it is disabled'), {'task': name})
                    continue
                if task._periodic_spacing == 0:
                    task._periodic_spacing = None
                cls._periodic_tasks.append((name, task))
                cls._periodic_spacing[name] = task._periodic_spacing
                cls._periodic_last_run[name] = task._periodic_last_run

        return


@six.add_metaclass(_PeriodicTasksMeta)
class PeriodicTasks(object):

    def run_periodic_tasks(self, context, raise_on_error=False):
        """Tasks to be run at a periodic interval."""
        idle_for = DEFAULT_INTERVAL
        for task_name, task in self._periodic_tasks:
            full_task_name = '.'.join([self.__class__.__name__, task_name])
            now = timeutils.utcnow()
            spacing = self._periodic_spacing[task_name]
            last_run = self._periodic_last_run[task_name]
            if spacing is not None and last_run is not None:
                due = last_run + datetime.timedelta(seconds=spacing)
                if not timeutils.is_soon(due, 0.2):
                    idle_for = min(idle_for, timeutils.delta_seconds(now, due))
                    continue
            if spacing is not None:
                idle_for = min(idle_for, spacing)
            LOG.debug(_('Running periodic task %(full_task_name)s'), {'full_task_name': full_task_name})
            self._periodic_last_run[task_name] = timeutils.utcnow()
            try:
                task(self, context)
            except Exception as e:
                if raise_on_error:
                    raise
                LOG.exception(_('Error during %(full_task_name)s: %(e)s'), {'full_task_name': full_task_name,'e': e})

            time.sleep(0)

        return idle_for
