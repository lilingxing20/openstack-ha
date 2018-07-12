#!/bin/bash
###
## config cinder-volume
###
#openstack-config --set /etc/cinder/cinder.conf DEFAULT rpc_backend rabbit
#openstack-config --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/cinder/cinder.conf DEFAULT glance_host controller_vip
#openstack-config --set /etc/cinder/cinder.conf DEFAULT glance_api_servers  http://controller_vip:9292
#openstack-config --set /etc/cinder/cinder.conf DEFAULT enabled_backends lvm
###
openstack-config --del /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_host
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_hosts controller1,controller2,controller3
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_ha_queues True
###
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://controller_vip:5000/v2.0
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken identity_uri http://controller_vip:35357
#openstack-config --set /etc/cinder/cinder.conf keystone_authtoken admin_user cinder
#openstack-config --set /etc/cinder/cinder.conf keystone_authtoken admin_tenant_name services
#openstack-config --set /etc/cinder/cinder.conf keystone_authtoken admin_password teamsun
### 
openstack-config --set /etc/cinder/cinder.conf database connection mysql://cinder:teamsun@controller_vip/cinder
## config lvm
#openstack-config --set /etc/cinder/cinder.conf lvm  iscsi_helper  lioadm
#openstack-config --set /etc/cinder/cinder.conf lvm  iscsi_ip_address  "$(hostname -s)"
#openstack-config --set /etc/cinder/cinder.conf lvm  volume_driver  cinder.volume.drivers.lvm.LVMVolumeDriver
#openstack-config --set /etc/cinder/cinder.conf lvm  volumes_dir  /var/lib/cinder/volumes
#openstack-config --set /etc/cinder/cinder.conf lvm  volume_backend_name  lvm
