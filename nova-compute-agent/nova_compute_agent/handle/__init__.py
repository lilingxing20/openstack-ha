# coding=utf-8

"""Host HA handlers"""

class BaseHandler(object):
    """Base class for Host HA handler."""

    def handle_host(self, host):
        """ Handle single host with fault.
        """
        return NotImplementedError()
