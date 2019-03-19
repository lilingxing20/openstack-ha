# coding=utf-8

"""Local storage of variables using weak references"""
import threading
import weakref

class WeakLocal(threading.local):

    def __getattribute__(self, attr):
        rval = super(WeakLocal, self).__getattribute__(attr)
        if rval:
            rval = rval()
        return rval

    def __setattr__(self, attr, value):
        value = weakref.ref(value)
        return super(WeakLocal, self).__setattr__(attr, value)


store = WeakLocal()
weak_store = WeakLocal()
strong_store = threading.local()
