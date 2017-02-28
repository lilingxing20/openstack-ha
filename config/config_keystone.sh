#!/bin/bash
###
##  config keystone 
###
openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_bind_host "$(hostname -s)"
openstack-config --set /etc/keystone/keystone.conf DEFAULT public_bind_host "$(hostname -s)"
##  rabbit
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_ha_queues True
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_hosts ha1,ha2,ha3
## database
openstack-config --set /etc/keystone/keystone.conf database connection "mysql://keystone_admin:teamsun@controller_vip/keystone"
