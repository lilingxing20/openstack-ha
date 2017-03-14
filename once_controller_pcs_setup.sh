#!/bin/bash

## vip
vip_addr=$(cat /etc/hosts | grep controller_vip | awk '{print $1}')
pcs resource create controller_vip ocf:heartbeat:IPaddr2 ip=${vip_addr} cidr_netmask=24 op start interval=0s timeout=20s stop interval=0s timeout=20s monitor interval=10s timeout=20s


## haproxy
pcs resource create haproxy systemd:haproxy op start interval=0s timeout=200s stop interval=0s timeout=200s monitor interval=60s --clone
pcs constraint order start controller_vip  then start haproxy-clone  option kind=Optional
pcs constraint colocation add controller_vip with haproxy-clone INFINITY


## core
pcs resource create openstack-core ocf:heartbeat:Dummy meta interleave=true op start interval=0s timeout=20 stop interval=0s timeout=20 monitor interval=10 timeout=20  --clone


## galera
pcs resource create galera galera additional_parameters='--open-files-limit=16384' enable_creation=true wsrep_cluster_address="gcomm://controller1,controller2,controller3"  meta master-max=3 ordered=true op promote timeout=300s on-fail=block --master
pcs constraint order promote galera-master then start openstack-core-clone option kind=Mandatory


## memcached
pcs resource create memcached systemd:memcached meta interleave=true op start interval=0s timeout=200s stop interval=0s timeout=200s monitor interval=60s --clone
pcs constraint order start memcached-clone then start openstack-core-clone option kind=Mandatory


## rabbitmq
pcs resource create rabbitmq rabbitmq-cluster set_policy='ha-all ^(?!amq\.).* {"ha-mode":"all"}' meta notify=true ordered=true interleave=true --clone
pcs constraint order start rabbitmq-clone then start openstack-core-clone option kind=Mandatory


## httpd
pcs resource create httpd systemd:httpd meta interleave=true op start interval=0s timeout=200s stop interval=0s timeout=200s monitor interval=60s --clone
pcs constraint order start openstack-core-clone then start httpd-clone option kind=Mandatory


## neutron
pcs resource create neutron-server systemd:neutron-server meta interleave=true op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create neutron-openvswitch-agent systemd:neutron-openvswitch-agent meta interleave=true op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create neutron-dhcp-agent systemd:neutron-dhcp-agent meta interleave=true op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create neutron-metadata-agent systemd:neutron-metadata-agent meta interleave=true op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create neutron-l3-agent systemd:neutron-l3-agent meta interleave=true op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create neutron-metering-agent systemd:neutron-metering-agent meta interleave=true op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create neutron-ovs-cleanup systemd:neutron-ovs-cleanup meta interleave=true op monitor interval=10s timeout=20 start interval=0s timeout=40s stop interval=0s timeout=300s --clone
pcs resource create neutron-netns-cleanup systemd:neutron-netns-cleanup meta interleave=true op monitor interval=10s timeout=20 start interval=0s timeout=40s stop interval=0s timeout=300s --clone

pcs constraint order start openstack-core-clone then start neutron-server-clone
pcs constraint order start neutron-server-clone then start neutron-openvswitch-agent-clone
pcs constraint order start neutron-openvswitch-agent-clone then start neutron-dhcp-agent-clone
pcs constraint order start neutron-dhcp-agent-clone then start neutron-l3-agent-clone
pcs constraint order start neutron-l3-agent-clone then start neutron-metadata-agent-clone
pcs constraint order start neutron-ovs-cleanup-clone then start neutron-netns-cleanup-clone
pcs constraint order start neutron-netns-cleanup-clone then start neutron-openvswitch-agent-clone

pcs constraint colocation add neutron-metadata-agent-clone with neutron-l3-agent-clone INFINITY
pcs constraint colocation add neutron-l3-agent-clone with neutron-dhcp-agent-clone INFINITY
pcs constraint colocation add neutron-dhcp-agent-clone with neutron-openvswitch-agent-clone INFINITY
pcs constraint colocation add neutron-openvswitch-agent-clone with neutron-netns-cleanup-clone INFINITY
pcs constraint colocation add neutron-netns-cleanup-clone with neutron-ovs-cleanup-clone INFINITY


## nova
pcs resource create openstack-nova-api systemd:openstack-nova-api meta interleave=true op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-nova-scheduler systemd:openstack-nova-scheduler meta interleave=true op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-nova-conductor systemd:openstack-nova-conductor meta interleave=true op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-nova-consoleauth systemd:openstack-nova-consoleauth meta interleave=true op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-nova-novncproxy systemd:openstack-nova-novncproxy meta interleave=true op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone

pcs constraint order start openstack-core-clone then start openstack-nova-consoleauth-clone option kind=Mandatory
pcs constraint order start openstack-nova-consoleauth-clone then start openstack-nova-novncproxy-clone  option kind=Mandatory
pcs constraint order start openstack-nova-novncproxy-clone then start openstack-nova-api-clone  option kind=Mandatory
pcs constraint order start openstack-nova-api-clone then start openstack-nova-scheduler-clone  option kind=Mandatory
pcs constraint order start openstack-nova-scheduler-clone then start openstack-nova-conductor-clone  option kind=Mandatory

pcs constraint colocation add openstack-nova-conductor-clone with openstack-nova-scheduler-clone INFINITY
pcs constraint colocation add openstack-nova-scheduler-clone with openstack-nova-api-clone INFINITY
pcs constraint colocation add openstack-nova-api-clone with openstack-nova-novncproxy-clone INFINITY
pcs constraint colocation add openstack-nova-novncproxy-clone with openstack-nova-consoleauth-clone INFINITY


## swift
pcs resource create openstack-swift-container systemd:openstack-swift-container op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-container-auditor systemd:openstack-swift-container-auditor op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-container-replicator systemd:openstack-swift-container-replicator op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-container-updater systemd:openstack-swift-container-updater op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone

pcs resource create openstack-swift-account systemd:openstack-swift-account op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-account-auditor systemd:openstack-swift-account-auditor op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-account-replicator systemd:openstack-swift-account-replicator op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-account-reaper systemd:openstack-swift-account-reaper op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone

pcs resource create openstack-swift-object systemd:openstack-swift-object op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-object-auditor systemd:openstack-swift-object-auditor op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-object-replicator systemd:openstack-swift-object-replicator op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-object-updater systemd:openstack-swift-object-updater op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-object-expirer systemd:openstack-swift-object-expirer op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone

pcs resource create openstack-swift-proxy systemd:openstack-swift-proxy op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
#
pcs constraint colocation add openstack-swift-container-clone with openstack-swift-container-auditor-clone INFINITY
pcs constraint colocation add openstack-swift-container-auditor-clone with openstack-swift-container-replicator-clone INFINITY
pcs constraint colocation add openstack-swift-container-replicator-clone with openstack-swift-container-updater-clone INFINITY
pcs constraint colocation add openstack-swift-container-updater-clone with openstack-swift-account-clone INFINITY
pcs constraint colocation add openstack-swift-account-clone with openstack-swift-account-auditor-clone INFINITY
pcs constraint colocation add openstack-swift-account-auditor-clone with openstack-replicator-clone INFINITY
pcs constraint colocation add openstack-swift-account-replicator-clone with openstack-swift-account-reaper-clone INFINITY
pcs constraint colocation add openstack-swift-account-reaper-clone with openstack-swift-object-clone INFINITY
pcs constraint colocation add openstack-object-clone with openstack-swift-object-auditor-clone INFINITY
pcs constraint colocation add openstack-object-auditor-clone with openstack-swift-object-replicator-clone INFINITY
pcs constraint colocation add openstack-object-replicator-clone with openstack-swift-object-updater-clone INFINITY
pcs constraint colocation add openstack-object-updater-clone with openstack-swift-object-expirer-clone INFINITY
pcs constraint colocation add openstack-object-expirer-clone with openstack-swift-proxy-clone INFINITY


## glance
pcs resource create openstack-glance-api systemd:openstack-glance-api meta interleave=true op monitor start-delay=10s --clone
pcs resource create openstack-glance-registry systemd:openstack-glance-registry meta interleave=true op monitor start-delay=10s --clone
pcs constraint order start openstack-core-clone then start openstack-glance-registry-clone option kind=Mandatory
pcs constraint order start openstack-glance-registry-clone then start openstack-glance-api-clone option kind=Mandatory

pcs constraint colocation add openstack-glance-api-clone with openstack-glance-registry-clone INFINITY


## heat
pcs resource create openstack-heat-api systemd:openstack-heat-api meta interleave=true op start interval=0s timeout=200s stop interval=0s timeout=200s monitor interval=60s --clone
pcs resource create openstack-heat-api-cfn systemd:openstack-heat-api-cfn meta interleave=true op start interval=0s timeout=200s stop interval=0s timeout=200s monitor interval=60s --clone
pcs resource create openstack-heat-api-cloudwatch systemd:openstack-heat-api-cloudwatch meta interleave=true op start interval=0s timeout=200s stop interval=0s timeout=200s monitor interval=60s --clone
pcs resource create openstack-heat-engine systemd:openstack-heat-engine meta interleave=true op start interval=0s timeout=200s stop interval=0s timeout=200s monitor interval=60s --clone

pcs constraint order start openstack-core-clone then start openstack-heat-api-clone
pcs constraint order start openstack-heat-api-clone  then start openstack-heat-api-cfn-clone
pcs constraint order start openstack-heat-api-cfn-clone  then start openstack-heat-api-cloudwatch-clone
pcs constraint order start openstack-heat-api-cloudwatch-clone  then start openstack-heat-engine-clone

pcs constraint colocation add openstack-heat-engine-clone with openstack-heat-api-cloudwatch-clone INFINITY
pcs constraint colocation add openstack-heat-api-cloudwatch-clone with openstack-heat-api-cfn-clone INFINITY
pcs constraint colocation add openstack-heat-api-cfn-clone with openstack-heat-api-clone INFINITY


## cinder
pcs resource create openstack-cinder-api systemd:openstack-cinder-api meta interleave=true op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-cinder-scheduler systemd:openstack-cinder-scheduler meta interleave=true op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-cinder-volume systemd:openstack-cinder-volume op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s

pcs constraint order start openstack-core-clone then start openstack-cinder-api-clone
pcs constraint order start openstack-cinder-api-clone then start openstack-cinder-scheduler-clone
pcs constraint order start openstack-cinder-scheduler-clone then start openstack-cinder-volume

pcs constraint colocation add openstack-cinder-scheduler-clone with openstack-cinder-api-clone INFINITY
pcs constraint colocation add openstack-cinder-volume with openstack-cinder-scheduler-clone INFINITY

