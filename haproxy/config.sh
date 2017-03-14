#!/bin/bash

CURDIR=$(cd $(dirname "$0") && pwd)

test -f /etc/haproxy/haproxy.cfg && mv /etc/haproxy/haproxy.cfg{,.bk}
cp ${CURDIR}/haproxy.cfg /etc/haproxy/

echo net.ipv4.ip_nonlocal_bind=1 >/etc/sysctl.d/haproxy.conf
echo 1 > /proc/sys/net/ipv4/ip_nonlocal_bind
sysctl -p

cp ${CURDIR}/haproxy-rsyslog.conf /etc/rsyslog.d/haproxy-rsyslog.conf
systemctl restart rsyslog
