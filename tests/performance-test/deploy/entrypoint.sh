#!/bin/sh

/usr/sbin/collectd -C /tmp/minimal-collectd.conf -f 2>&1 | tee /tmp/collectd_output

sleep 5