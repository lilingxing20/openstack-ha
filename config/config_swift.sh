#!/bin/bash
###
##  config account-server 
###
openstack-config --set /etc/swift/account-server.conf "DEFAULT" bind_ip "$(hostname -i)"
openstack-config --set /etc/swift/account-server.conf "pipeline:main" pipeline "healthcheck account-server"
openstack-config --set /etc/swift/account-server.conf "filter:healthcheck" use "egg:swift#healthcheck"
openstack-config --set /etc/swift/account-server.conf "filter:recon" use "egg:swift#recon"
openstack-config --set /etc/swift/account-server.conf "filter:recon" recon_cache_path /var/cache/swift
###
##  config container-server 
###
openstack-config --set /etc/swift/container-server.conf DEFAULT mount_check false
openstack-config --set /etc/swift/container-server.conf DEFAULT bind_ip "$(hostname -i)"
openstack-config --set /etc/swift/container-server.conf DEFAULT allowed_sync_hosts "controller1-internalapi,controller2-internalapi,controller3-internalapi"
openstack-config --set /etc/swift/container-server.conf "pipeline:main" pipeline "healthcheck container-server"
openstack-config --set /etc/swift/container-server.conf "filter:healthcheck" use "egg:swift#healthcheck"
openstack-config --set /etc/swift/container-server.conf "filter:recon" use "egg:swift#recon"
openstack-config --set /etc/swift/container-server.conf "filter:recon" recon_cache_path /var/cache/swift
###
##  config object-server 
###
openstack-config --set /etc/swift/object-server.conf DEFAULT bind_ip "$(hostname -i)"
openstack-config --set /etc/swift/object-server.conf DEFAULT mount_check false
openstack-config --set /etc/swift/object-server.conf "pipeline:main" pipeline "healthcheck recon object-server"
openstack-config --set /etc/swift/object-server.conf "filter:healthcheck" use "egg:swift#healthcheck"
openstack-config --set /etc/swift/object-server.conf "filter:recon" use "egg:swift#recon"
openstack-config --set /etc/swift/object-server.conf "filter:recon" recon_cache_path /var/cache/swift
###
##  config proxy-server 
###
openstack-config --set /etc/swift/proxy-server.conf DEFAULT bind_ip "$(hostname -i)"
openstack-config --set /etc/swift/proxy-server.conf DEFAULT workers 0
openstack-config --set /etc/swift/proxy-server.conf "filter:authtoken" auth_uri http://control_vip:5000/v2.0
openstack-config --set /etc/swift/proxy-server.conf "filter:authtoken" identity_uri http://control_vip:35357
openstack-config --set /etc/swift/proxy-server.conf "filter:cache" memcache_servers "controller1-internalapi:11211,controller2-internalapi:11211,controller3-internalapi:11211"
openstack-config --set /etc/swift/proxy-server.conf "filter:recon" use "egg:swift#recon"
openstack-config --set /etc/swift/proxy-server.conf "filter:recon" recon_cache_path /var/cache/swift
