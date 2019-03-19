# coding=utf-8

"""
System-level utilities and helper functions.
"""
import re
import sys
import unicodedata
import six
from nova_compute_agent.openstack.common.gettextutils import _
BYTE_MULTIPLIERS = {'': 1,
   't': 1099511627776,
   'g': 1073741824,
   'm': 1048576,
   'k': 1024
   }
BYTE_REGEX = re.compile('(^-?\\d+)(\\D*)')
TRUE_STRINGS = ('1', 't', 'true', 'on', 'y', 'yes')
FALSE_STRINGS = ('0', 'f', 'false', 'off', 'n', 'no')
SLUGIFY_STRIP_RE = re.compile('[^\\w\\s-]')
SLUGIFY_HYPHENATE_RE = re.compile('[-\\s]+')
_SANITIZE_KEYS = [
 'adminPass', 'admin_pass', 'password', 'admin_password']
_SANITIZE_PATTERNS_2 = []
_SANITIZE_PATTERNS_1 = []
_FORMAT_PATTERNS_1 = [
 '(%(key)s\\s*[=]\\s*)[^\\s^\\\'^\\"]+']
_FORMAT_PATTERNS_2 = ['(%(key)s\\s*[=]\\s*[\\"\\\']).*?([\\"\\\'])',
 '(%(key)s\\s+[\\"\\\']).*?([\\"\\\'])',
 '([-]{2}%(key)s\\s+)[^\\\'^\\"^=^\\s]+([\\s]*)',
 '(<%(key)s>).*?(</%(key)s>)',
 '([\\"\\\']%(key)s[\\"\\\']\\s*:\\s*[\\"\\\']).*?([\\"\\\'])',
 '([\\\'"].*?%(key)s[\\\'"]\\s*:\\s*u?[\\\'"]).*?([\\\'"])',
 '([\\\'"].*?%(key)s[\\\'"]\\s*,\\s*\\\'--?[A-z]+\\\'\\s*,\\s*u?[\'"]).*?([\'"])',
 '(%(key)s\\s*--?[A-z]+\\s*)\\S+(\\s*)']
for key in _SANITIZE_KEYS:
    for pattern in _FORMAT_PATTERNS_2:
        reg_ex = re.compile(pattern % {'key': key}, re.DOTALL)
        _SANITIZE_PATTERNS_2.append(reg_ex)

    for pattern in _FORMAT_PATTERNS_1:
        reg_ex = re.compile(pattern % {'key': key}, re.DOTALL)
        _SANITIZE_PATTERNS_1.append(reg_ex)

def int_from_bool_as_string(subject):
    """Interpret a string as a boolean and return either 1 or 0.
    
    Any string value in:
    
        ('True', 'true', 'On', 'on', '1')
    
    is interpreted as a boolean True.
    
    Useful for JSON-decoded stuff and config file parsing
    """
    return bool_from_string(subject) and 1 or 0


def bool_from_string(subject, strict=False):
    """Interpret a string as a boolean.
    
    A case-insensitive match is performed such that strings matching 't',
    'true', 'on', 'y', 'yes', or '1' are considered True and, when
    `strict=False`, anything else is considered False.
    
    Useful for JSON-decoded stuff and config file parsing.
    
    If `strict=True`, unrecognized values, including None, will raise a
    ValueError which is useful when parsing values passed in from an API call.
    Strings yielding False are 'f', 'false', 'off', 'n', 'no', or '0'.
    """
    if not isinstance(subject, basestring):
        subject = str(subject)
    lowered = subject.strip().lower()
    if lowered in TRUE_STRINGS:
        return True
    if lowered in FALSE_STRINGS:
        return False
    if strict:
        acceptable = ', '.join(("'%s'" % s for s in sorted(TRUE_STRINGS + FALSE_STRINGS)))
        msg = _("Unrecognized value '%(val)s', acceptable values are: %(acceptable)s") % {'val': subject,'acceptable': acceptable
           }
        raise ValueError(msg)
    else:
        return False


def safe_decode(text, incoming=None, errors='strict'):
    """Decodes incoming str using `incoming` if they're not already unicode.
    
    :param incoming: Text's current encoding
    :param errors: Errors handling policy. See here for valid
        values http://docs.python.org/2/library/codecs.html
    :returns: text or a unicode `incoming` encoded
                representation of it.
    :raises TypeError: If text is not an isntance of basestring
    """
    if not isinstance(text, basestring):
        raise TypeError("%s can't be decoded" % type(text))
    if isinstance(text, unicode):
        return text
    if not incoming:
        incoming = sys.stdin.encoding or sys.getdefaultencoding()
    try:
        return text.decode(incoming, errors)
    except UnicodeDecodeError:
        return text.decode('utf-8', errors)


def safe_encode(text, incoming=None, encoding='utf-8', errors='strict'):
    """Encodes incoming str/unicode using `encoding`.
    
    If incoming is not specified, text is expected to be encoded with
    current python's default encoding. (`sys.getdefaultencoding`)
    
    :param incoming: Text's current encoding
    :param encoding: Expected encoding for text (Default UTF-8)
    :param errors: Errors handling policy. See here for valid
        values http://docs.python.org/2/library/codecs.html
    :returns: text or a bytestring `encoding` encoded
                representation of it.
    :raises TypeError: If text is not an isntance of basestring
    """
    if not isinstance(text, basestring):
        raise TypeError("%s can't be encoded" % type(text))
    if not incoming:
        incoming = sys.stdin.encoding or sys.getdefaultencoding()
    if isinstance(text, unicode):
        return text.encode(encoding, errors)
    if text and encoding != incoming:
        text = safe_decode(text, incoming, errors)
        return text.encode(encoding, errors)
    return text


def to_bytes(text, default=0):
    """Converts a string into an integer of bytes.
    
    Looks at the last characters of the text to determine
    what conversion is needed to turn the input text into a byte number.
    Supports "B, K(B), M(B), G(B), and T(B)". (case insensitive)
    
    :param text: String input for bytes size conversion.
    :param default: Default return value when text is blank.
    
    """
    match = BYTE_REGEX.search(text)
    if match:
        magnitude = int(match.group(1))
        mult_key_org = match.group(2)
        if not mult_key_org:
            return magnitude
    elif text:
        msg = _('Invalid string format: %s') % text
        raise TypeError(msg)
    else:
        return default
    mult_key = mult_key_org.lower().replace('b', '', 1)
    multiplier = BYTE_MULTIPLIERS.get(mult_key)
    if multiplier is None:
        msg = _('Unknown byte multiplier: %s') % mult_key_org
        raise TypeError(msg)
    return magnitude * multiplier


def to_slug(value, incoming=None, errors='strict'):
    """Normalize string.
    
    Convert to lowercase, remove non-word characters, and convert spaces
    to hyphens.
    
    Inspired by Django's `slugify` filter.
    
    :param value: Text to slugify
    :param incoming: Text's current encoding
    :param errors: Errors handling policy. See here for valid
        values http://docs.python.org/2/library/codecs.html
    :returns: slugified unicode representation of `value`
    :raises TypeError: If text is not an instance of basestring
    """
    value = safe_decode(value, incoming, errors)
    value = unicodedata.normalize('NFKD', value).encode('ascii', 'ignore').decode('ascii')
    value = SLUGIFY_STRIP_RE.sub('', value).strip().lower()
    return SLUGIFY_HYPHENATE_RE.sub('-', value)


def mask_password(message, secret='***'):
    """Replace password with 'secret' in message.
    
    :param message: The string which includes security information.
    :param secret: value with which to replace passwords.
    :returns: The unicode value of message with the password fields masked.
    
    For example:
    
    >>> mask_password("'adminPass' : 'aaaaa'")
    "'adminPass' : '***'"
    >>> mask_password("'admin_pass' : 'aaaaa'")
    "'admin_pass' : '***'"
    >>> mask_password('"password" : "aaaaa"')
    '"password" : "***"'
    >>> mask_password("'original_password' : 'aaaaa'")
    "'original_password' : '***'"
    >>> mask_password("u'original_password' :   u'aaaaa'")
    "u'original_password' :   u'***'"
    """
    message = six.text_type(message)
    if not any((key in message for key in _SANITIZE_KEYS)):
        return message
    substitute = '\\g<1>' + secret + '\\g<2>'
    for pattern in _SANITIZE_PATTERNS_2:
        message = re.sub(pattern, substitute, message)

    substitute = '\\g<1>' + secret
    for pattern in _SANITIZE_PATTERNS_1:
        message = re.sub(pattern, substitute, message)

    return message
