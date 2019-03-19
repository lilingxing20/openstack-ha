# coding=utf-8

"""
gettext for openstack-common modules.

Usual usage in an openstack.common module:

    from nova_compute_agent.openstack.common.gettextutils import _
"""
import copy
import functools
import gettext
import locale
from logging import handlers
import os
import re
from babel import localedata
import six
_localedir = os.environ.get('nova_compute_agent'.upper() + '_LOCALEDIR')
_t = gettext.translation('nova_compute_agent', localedir=_localedir, fallback=True)
_t_log_levels = dict(((level, gettext.translation('nova_compute_agent-log-' + level, localedir=_localedir, fallback=True)) for level in ['info', 'warning', 'error', 'critical']))
_AVAILABLE_LANGUAGES = {}
USE_LAZY = False

def enable_lazy():
    """Convenience function for configuring _() to use lazy gettext
    
    Call this at the start of execution to enable the gettextutils._
    function to use lazy gettext functionality. This is useful if
    your project is importing _ directly instead of using the
    gettextutils.install() way of importing the _ function.
    """
    global USE_LAZY
    USE_LAZY = True


def _(msg):
    if USE_LAZY:
        return Message(msg, domain='nova')
    else:
        if six.PY3:
            return _t.gettext(msg)
        return _t.ugettext(msg)


def _log_translation(msg, level):
    """Build a single translation of a log message
    """
    if USE_LAZY:
        return Message(msg, domain='nova_compute_agent-log-' + level)
    else:
        translator = _t_log_levels[level]
        if six.PY3:
            return translator.gettext(msg)
        return translator.ugettext(msg)


_LI = functools.partial(_log_translation, level='info')
_LW = functools.partial(_log_translation, level='warning')
_LE = functools.partial(_log_translation, level='error')
_LC = functools.partial(_log_translation, level='critical')

def install(domain, lazy=False):
    """Install a _() function using the given translation domain.
    
    Given a translation domain, install a _() function using gettext's
    install() function.
    
    The main difference from gettext.install() is that we allow
    overriding the default localedir (e.g. /usr/share/locale) using
    a translation-domain-specific environment variable (e.g.
    NOVA_LOCALEDIR).
    
    :param domain: the translation domain
    :param lazy: indicates whether or not to install the lazy _() function.
                 The lazy _() introduces a way to do deferred translation
                 of messages by installing a _ that builds Message objects,
                 instead of strings, which can then be lazily translated into
                 any available locale.
    """
    if lazy:

        def _lazy_gettext(msg):
            """Create and return a Message object.
            
            Lazy gettext function for a given domain, it is a factory method
            for a project/module to get a lazy gettext function for its own
            translation domain (i.e. nova, glance, cinder, etc.)
            
            Message encapsulates a string so that we can translate
            it later when needed.
            """
            return Message(msg, domain=domain)

        from six import moves
        moves.builtins.__dict__['_'] = _lazy_gettext
    else:
        localedir = '%s_LOCALEDIR' % domain.upper()
        if six.PY3:
            gettext.install(domain, localedir=os.environ.get(localedir))
        else:
            gettext.install(domain, localedir=os.environ.get(localedir), unicode=True)


class Message(six.text_type):
    """A Message object is a unicode object that can be translated.
    
    Translation of Message is done explicitly using the translate() method.
    For all non-translation intents and purposes, a Message is simply unicode,
    and can be treated as such.
    """

    def __new__(cls, msgid, msgtext=None, params=None, domain='nova_compute_agent', *args):
        """Create a new Message object.
        
        In order for translation to work gettext requires a message ID, this
        msgid will be used as the base unicode text. It is also possible
        for the msgid and the base unicode text to be different by passing
        the msgtext parameter.
        """
        if not msgtext:
            msgtext = Message._translate_msgid(msgid, domain)
        msg = super(Message, cls).__new__(cls, msgtext)
        msg.msgid = msgid
        msg.domain = domain
        msg.params = params
        return msg

    def translate(self, desired_locale=None):
        """Translate this message to the desired locale.
        
        :param desired_locale: The desired locale to translate the message to,
                               if no locale is provided the message will be
                               translated to the system's default locale.
        
        :returns: the translated message in unicode
        """
        translated_message = Message._translate_msgid(self.msgid, self.domain, desired_locale)
        if self.params is None:
            return translated_message
        else:
            translated_params = _translate_args(self.params, desired_locale)
            translated_message = translated_message % translated_params
            return translated_message

    @staticmethod
    def _translate_msgid(msgid, domain, desired_locale=None):
        if not desired_locale:
            system_locale = locale.getdefaultlocale()
            if not system_locale[0]:
                desired_locale = 'en_US'
            else:
                desired_locale = system_locale[0]
        locale_dir = os.environ.get(domain.upper() + '_LOCALEDIR')
        lang = gettext.translation(domain, localedir=locale_dir, languages=[
         desired_locale], fallback=True)
        if six.PY3:
            translator = lang.gettext
        else:
            translator = lang.ugettext
        translated_message = translator(msgid)
        return translated_message

    def __mod__(self, other):
        params = self._sanitize_mod_params(other)
        unicode_mod = super(Message, self).__mod__(params)
        modded = Message(self.msgid, msgtext=unicode_mod, params=params, domain=self.domain)
        return modded

    def _sanitize_mod_params(self, other):
        """Sanitize the object being modded with this Message.
        
        - Add support for modding 'None' so translation supports it
        - Trim the modded object, which can be a large dictionary, to only
        those keys that would actually be used in a translation
        - Snapshot the object being modded, in case the message is
        translated, it will be used as it was when the Message was created
        """
        if other is None:
            params = (
             other,)
        elif isinstance(other, dict):
            params = self._trim_dictionary_parameters(other)
        else:
            params = self._copy_param(other)
        return params

    def _trim_dictionary_parameters(self, dict_param):
        """Return a dict that only has matching entries in the msgid."""
        keys = re.findall('(?:[^%]|^)?%\\((\\w*)\\)[a-z]', self.msgid)
        if not keys and re.findall('(?:[^%]|^)%[a-z]', self.msgid):
            params = self._copy_param(dict_param)
        else:
            params = {}
            src = {}
            if isinstance(self.params, dict):
                src.update(self.params)
            src.update(dict_param)
            for key in keys:
                params[key] = self._copy_param(src[key])

        return params

    def _copy_param(self, param):
        try:
            return copy.deepcopy(param)
        except TypeError:
            return six.text_type(param)

    def __add__(self, other):
        msg = _('Message objects do not support addition.')
        raise TypeError(msg)

    def __radd__(self, other):
        return self.__add__(other)

    def __str__(self):
        msg = _('Message objects do not support str() because they may contain non-ascii characters. Please use unicode() or translate() instead.')
        raise UnicodeError(msg)


def get_available_languages(domain):
    """Lists the available languages for the given translation domain.
    
    :param domain: the domain to get languages for
    """
    if domain in _AVAILABLE_LANGUAGES:
        return copy.copy(_AVAILABLE_LANGUAGES[domain])
    else:
        localedir = '%s_LOCALEDIR' % domain.upper()
        find = lambda x: gettext.find(domain, localedir=os.environ.get(localedir), languages=[
         x])
        language_list = [
         'en_US']
        list_identifiers = getattr(localedata, 'list', None) or getattr(localedata, 'locale_identifiers')
        locale_identifiers = list_identifiers()
        for i in locale_identifiers:
            if find(i) is not None:
                language_list.append(i)

        aliases = {'zh': 'zh_CN','zh_Hant_HK': 'zh_HK',
           'zh_Hant': 'zh_TW',
           'fil': 'tl_PH'
           }
        for locale, alias in six.iteritems(aliases):
            if locale in language_list and alias not in language_list:
                language_list.append(alias)

        _AVAILABLE_LANGUAGES[domain] = language_list
        return copy.copy(language_list)


def translate(obj, desired_locale=None):
    """Gets the translated unicode representation of the given object.
    
    If the object is not translatable it is returned as-is.
    If the locale is None the object is translated to the system locale.
    
    :param obj: the object to translate
    :param desired_locale: the locale to translate the message to, if None the
                           default system locale will be used
    :returns: the translated object in unicode, or the original object if
              it could not be translated
    """
    message = obj
    if not isinstance(message, Message):
        message = six.text_type(obj)
    if isinstance(message, Message):
        return message.translate(desired_locale)
    return obj


def _translate_args(args, desired_locale=None):
    """Translates all the translatable elements of the given arguments object.
    
    This method is used for translating the translatable values in method
    arguments which include values of tuples or dictionaries.
    If the object is not a tuple or a dictionary the object itself is
    translated if it is translatable.
    
    If the locale is None the object is translated to the system locale.
    
    :param args: the args to translate
    :param desired_locale: the locale to translate the args to, if None the
                           default system locale will be used
    :returns: a new args object with the translated contents of the original
    """
    if isinstance(args, tuple):
        return tuple((translate(v, desired_locale) for v in args))
    if isinstance(args, dict):
        translated_dict = {}
        for k, v in six.iteritems(args):
            translated_v = translate(v, desired_locale)
            translated_dict[k] = translated_v

        return translated_dict
    return translate(args, desired_locale)


class TranslationHandler(handlers.MemoryHandler):
    """Handler that translates records before logging them.
    
    The TranslationHandler takes a locale and a target logging.Handler object
    to forward LogRecord objects to after translating them. This handler
    depends on Message objects being logged, instead of regular strings.
    
    The handler can be configured declaratively in the logging.conf as follows:
    
        [handlers]
        keys = translatedlog, translator
    
        [handler_translatedlog]
        class = handlers.WatchedFileHandler
        args = ('/var/log/api-localized.log',)
        formatter = context
    
        [handler_translator]
        class = openstack.common.log.TranslationHandler
        target = translatedlog
        args = ('zh_CN',)
    
    If the specified locale is not available in the system, the handler will
    log in the default locale.
    """

    def __init__(self, locale=None, target=None):
        """Initialize a TranslationHandler
        
        :param locale: locale to use for translating messages
        :param target: logging.Handler object to forward
                       LogRecord objects to after translation
        """
        handlers.MemoryHandler.__init__(self, capacity=0, target=target)
        self.locale = locale

    def setFormatter(self, fmt):
        self.target.setFormatter(fmt)

    def emit(self, record):
        original_msg = record.msg
        original_args = record.args
        try:
            self._translate_and_log_record(record)
        finally:
            record.msg = original_msg
            record.args = original_args

    def _translate_and_log_record(self, record):
        record.msg = translate(record.msg, self.locale)
        record.args = _translate_args(record.args, self.locale)
        self.target.emit(record)
