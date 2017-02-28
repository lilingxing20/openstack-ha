#!/bin/bash
###
##  config nova api
###
openstack-config --set /etc/nova/nova.conf DEFAULT osapi_compute_listen "$(hostname -s)"
openstack-config --set /etc/nova/nova.conf DEFAULT metadata_listen "$(hostname -s)"
#openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
#openstack-config --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
#openstack-config --set /etc/nova/nova.conf DEFAULT use_neutron True
#openstack-config --set /etc/nova/nova.conf DEFAULT allow_resize_to_same_host True
openstack-config --set /etc/nova/nova.conf DEFAULT injected_network_template '$pybasedir/nova/virt/interfaces.template'
#openstack-config --set /etc/nova/nova.conf DEFAULT image_service "nova.image.glance.GlanceImageService"
#openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
#openstack-config --set /etc/nova/nova.conf DEFAULT network_api_class  nova.network.neutronv2.api.API
#openstack-config --set /etc/nova/nova.conf DEFAULT security_group_api neutron
##openstack-config --set /etc/nova/nova.conf DEFAULT metadata_host "$(hostname -s)"
openstack-config --set /etc/nova/nova.conf DEFAULT osapi_volume_listen "$(hostname -s)"
openstack-config --set /etc/nova/nova.conf DEFAULT novncproxy_host "$(hostname -s)"
### config api_database
openstack-config --set /etc/nova/nova.conf api_database connection "mysql+pymysql://nova_api:teamsun@controller_vip/nova_api"
### config database
openstack-config --set /etc/nova/nova.conf database connection mysql+pymysql://nova:teamsun@controller_vip/nova
### config glance
openstack-config --set /etc/nova/nova.conf glance api_servers http://controller_vip:9292
###  config authtoken
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri http://controller_vip:5000/v2.0
openstack-config --set /etc/nova/nova.conf keystone_authtoken identity_uri http://controller_vip:35357
#del#openstack-config --set /etc/nova/nova.conf keystone_authtoken memcached_servers  ha1:11211,ha2:11211,ha3:11211
#openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_user nova
#openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_tenant_name services
#openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_password teamsun
### config neutron
#openstack-config --set /etc/nova/nova.conf neutron service_metadata_proxy True
#openstack-config --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret teamsun
openstack-config --set /etc/nova/nova.conf neutron url  http://controller_vip:9696
#openstack-config --set /etc/nova/nova.conf neutron region_name RegionOne
#openstack-config --set /etc/nova/nova.conf neutron ovs_bridge br-int
#openstack-config --set /etc/nova/nova.conf neutron extension_sync_interval 600
openstack-config --set /etc/nova/nova.conf neutron auth_url http://controller_vip:35357/v3
#openstack-config --set /etc/nova/nova.conf neutron auth_type password
#openstack-config --set /etc/nova/nova.conf neutron username neutron
#openstack-config --set /etc/nova/nova.conf neutron password teamsun
#openstack-config --set /etc/nova/nova.conf neutron project_domain_name Default
#openstack-config --set /etc/nova/nova.conf neutron user_domain_name Default
#openstack-config --set /etc/nova/nova.conf neutron project_name services
#openstack-config --set /etc/nova/nova.conf neutron auth_plugin v3password
### config rabbit
openstack-config --del /etc/nova/nova.conf oslo_messaging_rabbit rabbit_host
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_hosts ha1,ha2,ha3
### config cache 
openstack-config --set /etc/nova/nova.conf cache backend oslo_cache.memcache_pool
openstack-config --set /etc/nova/nova.conf cache enabled true
openstack-config --set /etc/nova/nova.conf cache memcache_servers ha1:11211,ha2:11211,ha3:11211
