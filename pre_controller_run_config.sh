#!/bin/bash

## hosts
cp hosts /etc/hosts

## openstack
bash -x config/config_cinder.sh
bash -x config/config_volume.sh
bash -x config/config_swift.sh
bash -x config/config_glance.sh
bash -x config/config_heat.sh
bash -x config/config_httpd.sh
bash -x config/config_keystone.sh
bash -x config/config_neutron.sh
bash -x config/config_nova.sh

## pcs
yum install -y pcs pacemaker corosync fence-agents-all resource-agents
systemctl enable pcsd
systemctl start pcsd
echo 'password' | passwd --stdin hacluster

## hapryx
yum install -y haproxy
bash -x haproxy/config.sh 

## galera
bash -x  galera/config.sh 

