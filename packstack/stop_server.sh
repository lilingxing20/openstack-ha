#!/bin/bash
## nova
systemctl stop openstack-nova-api
systemctl stop openstack-nova-cert
systemctl stop openstack-nova-conductor
systemctl stop openstack-nova-consoleauth
systemctl stop openstack-nova-novncproxy
systemctl stop openstack-nova-scheduler
## heat
systemctl stop openstack-heat-api-cfn
systemctl stop openstack-heat-api
systemctl stop openstack-heat-engine
## glance
systemctl stop openstack-glance-api
systemctl stop openstack-glance-registry
## cinder
systemctl stop openstack-cinder-api
systemctl stop openstack-cinder-volume
systemctl stop openstack-cinder-scheduler
systemctl stop openstack-cinder-backup
## neutron
systemctl stop neutron-metadata-agent
systemctl stop neutron-dhcp-agent
systemctl stop neutron-metering-agent
systemctl stop neutron-l3-agent
systemctl stop neutron-openvswitch-agent
systemctl stop neutron-ovs-cleanup
systemctl stop neutron-server
## swift
systemctl stop openstack-swift-container-replicator.service
systemctl stop openstack-swift-container-auditor.service
systemctl stop openstack-swift-container.service
systemctl stop openstack-swift-object-expirer.service
systemctl stop openstack-swift-proxy.service
systemctl stop openstack-swift-account-reaper.service
systemctl stop openstack-swift-account-replicator.service
systemctl stop openstack-swift-account-auditor.service
systemctl stop openstack-swift-account.service
systemctl stop openstack-swift-object.service
systemctl stop openstack-swift-object-replicator.service
systemctl stop openstack-swift-object-auditor.service
systemctl stop openstack-swift-object-updater.service
systemctl stop openstack-swift-container-updater.service
## http mysql rabbit
systemctl stop httpd
systemctl stop mariadb
systemctl stop rabbitmq-server
systemctl stop iptables
systemctl stop memcached


## 取消已部署的openstack所有组件的开机启动服务项
## nova
systemctl disable nova-api
systemctl disable openstack-nova-api
systemctl disable openstack-nova-cert
systemctl disable openstack-nova-conductor
systemctl disable openstack-nova-consoleauth
systemctl disable openstack-nova-novncproxy
systemctl disable openstack-nova-scheduler
## heat
systemctl disable openstack-heat-api-cfn
systemctl disable openstack-heat-api
systemctl disable openstack-heat-engine
## glance
systemctl disable openstack-glance-api
systemctl disable openstack-glance-registry
## cinder
systemctl disable openstack-cinder-api
systemctl disable openstack-cinder-volume
systemctl disable openstack-cinder-scheduler
## neutron
systemctl disable neutron-metadata-agent
systemctl disable neutron-dhcp-agent
systemctl disable neutron-metering-agent
systemctl disable neutron-l3-agent
systemctl disable neutron-openvswitch-agent
systemctl disable neutron-ovs-cleanup
systemctl disable neutron-server
## swift
systemctl disable openstack-swift-container-replicator.service
systemctl disable openstack-swift-container-auditor.service
systemctl disable openstack-swift-container.service
systemctl disable openstack-swift-object-expirer.service
systemctl disable openstack-swift-proxy.service
systemctl disable openstack-swift-account-reaper.service
systemctl disable openstack-swift-account-replicator.service
systemctl disable openstack-swift-account-auditor.service
systemctl disable openstack-swift-account.service
systemctl disable openstack-swift-object.service
systemctl disable openstack-swift-object-replicator.service
systemctl disable openstack-swift-object-auditor.service
systemctl disable openstack-swift-object-updater.service
systemctl disable openstack-swift-container-updater.service
## http mysql rabbit
systemctl disable httpd
systemctl disable mariadb
systemctl disable rabbitmq-server
systemctl disable iptables
systemctl disable memcached

