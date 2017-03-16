#!/bin/bash
###
##  config keystone 
###
openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_bind_host "$(hostname -s)-internalapi"
openstack-config --set /etc/keystone/keystone.conf DEFAULT public_bind_host "$(hostname -s)-internalapi"
##  rabbit
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_ha_queues True
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_hosts controller1-internalapi,controller2-internalapi,controller3-internalapi
## database
openstack-config --set /etc/keystone/keystone.conf database connection "mysql://keystone_admin:teamsun@control_vip/keystone"
