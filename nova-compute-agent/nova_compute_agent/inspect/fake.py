# coding=utf-8

from nova_compute_agent import inspect

class FakeInspector(inspect.BaseInspector):
    """Fake inspector."""

    def _is_ok(self, host):
        """ return True if host has fault, each subclass should implement this.
        """
        return True
