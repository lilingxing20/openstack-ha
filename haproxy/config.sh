#!/bin/bash

CURDIR=$(cd $(dirname "$0") && pwd)

test -f /etc/haproxy/haproxy.cfg && mv /etc/haproxy/haproxy.cfg{,.bk}
cp ${CURDIR}/haproxy.cfg /etc/haproxy/
echo 1 > /proc/sys/net/ipv4/ip_nonlocal_bind
cp ${CURDIR}/haproxy-rsyslog.conf /etc/sysctl.d/
sysctl -p
