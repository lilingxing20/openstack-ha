#!/bin/bash

CURDIR=$(cd $(dirname "$0") && pwd)

test -f /etc/my.cnf.d/galera.cnf && mv /etc/my.cnf.d/galera.cnf{,.bk}
test -f etc/my.cnf.d/server.cnf && mv /etc/my.cnf.d/server.cnf{,.bk}
cp ${CURDIR}/galera_$(hostname -s).cnf /etc/my.cnf.d/galera.cnf
