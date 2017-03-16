#!/bin/bash
###
##  config cinder-api
###
#openstack-config --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/cinder/cinder.conf DEFAULT osapi_volume_listen "$(hostname -s)-internalapi"
#openstack-config --set /etc/cinder/cinder.conf DEFAULT rpc_backend rabbit
## database
openstack-config --set /etc/cinder/cinder.conf database connection mysql://cinder:teamsun@control_vip/cinder
## authtoken
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://control_vip:5000/v2.0
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken identity_uri http://control_vip:35357
#openstack-config --set /etc/cinder/cinder.conf keystone_authtoken admin_user cinder
#openstack-config --set /etc/cinder/cinder.conf keystone_authtoken admin_tenant_name services
#openstack-config --set /etc/cinder/cinder.conf keystone_authtoken admin_password teamsun
## rabbit
openstack-config --del /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_host
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_hosts controller1-internalapi,controller2-internalapi,controller3-internalapi
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_ha_queues True

