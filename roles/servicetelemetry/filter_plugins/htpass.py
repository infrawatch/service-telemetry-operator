#!/usr/bin/env python3
from hashlib import sha1
from base64 import b64decode, b64encode

class FilterModule(object):
    def filters(self):
        return {
            'htpasswd_sha1': self.htpasswd_sha1
        }

    def htpasswd_sha1(self, password):
        """Convert from plaintext to htpasswd compatible SHA1
        This filter will return a SHA1 password hash for use in htpasswd files.
        SHA1 is (highly) deprecated, but required by oauth_proxy until OCP 4.8 https://bugzilla.redhat.com/show_bug.cgi?id=1874322
        Jinja sha1 filter only outputs in hexdigest mode, but we require a base64 of the binary sha1 hash
        >>> htpasswd_sha1('password')
        '{SHA}W6ph5Mm5Pz8GgiULbPgzG37mj9g='
        """
        return "{SHA}" + b64encode(sha1(password.encode()).digest()).decode()
