#!/bin/bash
###
##  config glance-api 
###
openstack-config --set /etc/glance/glance-api.conf  DEFAULT bind_host "$(hostname -s)"
openstack-config --set /etc/glance/glance-api.conf  DEFAULT registry_host controller_vip
openstack-config --set /etc/glance/glance-api.conf database connection "mysql+pymysql://glance:teamsun@controller_vip/glance"
##  authtoken
openstack-config --set /etc/glance/glance-api.conf  keystone_authtoken auth_uri http://controller_vip:5000/v2.0
openstack-config --set /etc/glance/glance-api.conf  keystone_authtoken identity_uri http://controller_vip:35357
#openstack-config --set /etc/glance/glance-api.conf  keystone_authtoken admin_tenant_name services
#openstack-config --set /etc/glance/glance-api.conf  keystone_authtoken admin_user glance
#openstack-config --set /etc/glance/glance-api.conf  keystone_authtoken admin_password teamsun
##  paste_deploy
#openstack-config --set /etc/glance/glance-api.conf  paste_deploy flavor keystone
##  glance_store
#openstack-config --set /etc/glance/glance-api.conf  glance_store stores file,http,swift
#openstack-config --set /etc/glance/glance-api.conf  glance_store stores glance.store.http.Store,glance.store.swift.Store
openstack-config --set /etc/glance/glance-api.conf  glance_store default_store swift
openstack-config --set /etc/glance/glance-api.conf  glance_store swift_store_endpoint_type internalURL
openstack-config --set /etc/glance/glance-api.conf  glance_store swift_store_container glance
openstack-config --set /etc/glance/glance-api.conf  glance_store swift_store_large_object_size 5120
openstack-config --set /etc/glance/glance-api.conf  glance_store swift_store_create_container_on_put True
openstack-config --set /etc/glance/glance-api.conf  glance_store default_swift_reference ref1
openstack-config --set /etc/glance/glance-api.conf  glance_store swift_store_config_file /etc/glance/glance-swift.conf
###
##  config glance-swift
###
openstack-config --set /etc/glance/glance-swift.conf  ref1 user services:glance
openstack-config --set /etc/glance/glance-swift.conf  ref1 auth_version 2
openstack-config --set /etc/glance/glance-swift.conf  ref1 auth_address http://controller_vip:5000/v2.0
openstack-config --set /etc/glance/glance-swift.conf  ref1 key teamsun
###
##  config glance-registry 
###
openstack-config --set /etc/glance/glance-registry.conf  DEFAULT bind_host "$(hostname -s)"
openstack-config --set /etc/glance/glance-registry.conf  database connection "mysql+pymysql://glance:teamsun@controller_vip/glance"
##  authtoken
openstack-config --set /etc/glance/glance-registry.conf  keystone_authtoken auth_uri http://controller_vip:5000/v2.0
openstack-config --set /etc/glance/glance-registry.conf  keystone_authtoken identity_uri http://controller_vip:35357
#openstack-config --set /etc/glance/glance-registry.conf  keystone_authtoken admin_tenant_name services
#openstack-config --set /etc/glance/glance-registry.conf  keystone_authtoken admin_user glance
#openstack-config --set /etc/glance/glance-registry.conf  keystone_authtoken admin_password teamsun
##  paste_deploy
#openstack-config --set /etc/glance/glance-registry.conf  paste_deploy flavor keystone
###
##  config glance-cache 
###
openstack-config --set /etc/glance/glance-cache.conf  DEFAULT registry_host "controller_vip"
openstack-config --set /etc/glance/glance-cache.conf  DEFAULT auth_url http://controller_vip:5000/v2.0


