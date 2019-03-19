# coding=utf-8

"""
Exception related utilities.
"""
import logging
import sys
import time
import traceback
import six
from nova_compute_agent.openstack.common.gettextutils import _

class save_and_reraise_exception(object):
    """Save current exception, run some code and then re-raise.
    
    In some cases the exception context can be cleared, resulting in None
    being attempted to be re-raised after an exception handler is run. This
    can happen when eventlet switches greenthreads or when running an
    exception handler, code raises and catches an exception. In both
    cases the exception context will be cleared.
    
    To work around this, we save the exception state, run handler code, and
    then re-raise the original exception. If another exception occurs, the
    saved exception is logged and the new exception is re-raised.
    
    In some cases the caller may not want to re-raise the exception, and
    for those circumstances this context provides a reraise flag that
    can be used to suppress the exception.  For example:
    
    except Exception:
        with save_and_reraise_exception() as ctxt:
            decide_if_need_reraise()
            if not should_be_reraised:
                ctxt.reraise = False
    """

    def __init__(self):
        self.reraise = True

    def __enter__(self):
        self.type_, self.value, self.tb = sys.exc_info()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is not None:
            logging.error(_('Original exception being dropped: %s'), traceback.format_exception(self.type_, self.value, self.tb))
            return False
        else:
            if self.reraise:
                six.reraise(self.type_, self.value, self.tb)
            return


def forever_retry_uncaught_exceptions(infunc):

    def inner_func(*args, **kwargs):
        last_log_time = 0
        last_exc_message = None
        exc_count = 0
        while True:
            try:
                return infunc(*args, **kwargs)
            except Exception as exc:
                this_exc_message = six.u(str(exc))
                if this_exc_message == last_exc_message:
                    exc_count += 1
                else:
                    exc_count = 1
                cur_time = int(time.time())
                if cur_time - last_log_time > 60 or this_exc_message != last_exc_message:
                    logging.exception(_('Unexpected exception occurred %d time(s)... retrying.') % exc_count)
                    last_log_time = cur_time
                    last_exc_message = this_exc_message
                    exc_count = 0
                time.sleep(1)

        return

    return inner_func