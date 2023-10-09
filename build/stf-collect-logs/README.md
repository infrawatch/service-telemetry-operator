stf-collect-logs
================

This role collects logs that are useful for debugging an STF deployment.

Once the logs are collected, the user will need to fetch the logs themselves.

Requirements
------------


Role Variables
--------------

* `logfile_dir` - The location that the logs will be created in on the remote host(s).

Dependencies
------------


Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }

License
-------

Apache 2

Author Information
------------------

Red Hat
