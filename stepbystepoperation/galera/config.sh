#!/bin/bash

CURDIR=$(cd $(dirname "$0") && pwd)

test -f /etc/my.cnf.d/galera.cnf && mv /etc/my.cnf.d/galera.cnf{,.$(date +%Y%m%d%H%M%S)}
test -f etc/my.cnf.d/server.cnf && mv /etc/my.cnf.d/server.cnf{,.$(date +%Y%m%d%H%M%S)}
cp ${CURDIR}/galera_$(hostname -s).cnf /etc/my.cnf.d/galera.cnf

test -f /etc/xinetd.d/galera-monitor || cp ${CURDIR}/galera-monitor /etc/xinetd.d/galera-monitor
test -f /etc/sysconfig/clustercheck || cp ${CURDIR}/clustercheck /etc/sysconfig/clustercheck
systemctl restart xinetd
