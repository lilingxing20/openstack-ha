#!/bin/bash
###
##  config neutron server
###
openstack-config --set /etc/neutron/neutron.conf DEFAULT bind_host  "$(hostname -s)"
#openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy  keystone
#openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend  rabbit
#openstack-config --set /etc/neutron/neutron.conf DEFAULT router_scheduler_driver  neutron.scheduler.l3_agent_scheduler.ChanceScheduler
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_url  "http://controller_vip:8774/v2"
## database
openstack-config --set /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:teamsun@controller_vip/neutron
## authtoken
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://controller_vip:5000/v2.0
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken identity_uri http://controller_vip:35357
#openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_user neutron
#openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_tenant_name services
#openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_password teamsun
##  config neutron for nova
# openstack-config --set /etc/neutron/neutron.conf nova region_name RegionOne
openstack-config --set /etc/neutron/neutron.conf nova auth_url http://controller_vip:35357
#openstack-config --set /etc/neutron/neutron.conf nova auth_type password
#openstack-config --set /etc/neutron/neutron.conf nova username nova
#openstack-config --set /etc/neutron/neutron.conf nova password teamsun
#openstack-config --set /etc/neutron/neutron.conf nova project_domain_id default
#openstack-config --set /etc/neutron/neutron.conf nova user_domain_id default
#openstack-config --set /etc/neutron/neutron.conf nova project_name services
#openstack-config --set /etc/neutron/neutron.conf nova tenant_name services
## rabbit
openstack-config --del /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_host
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_hosts controller1,controller2,controller3
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_ha_queues True
###
##  config neutron l2 agent
###
#openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin  ml2
##openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin  neutron.plugins.ml2.plugin.Ml2Plugin
#openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins  router,metering
##
#openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers vlan
#openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vlan
#openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch
#openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vlan network_vlan_ranges vlan_phy:1:4094
##
test -f /etc/neutron/plugin.ini || ln -s plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
###
##  config neutron openvswitch agent
###
#openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings vlan_phy:br-vlan
###
##  config neutron l3 agent
###
#openstack-config --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
###
##  config neutron dhcp agent
###
#openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver  neutron.agent.linux.interface.OVSInterfaceDriver
#openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver  neutron.agent.linux.dhcp.Dnsmasq
#openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata  true
#openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT enable_metadata_network  true
###
##  config neutron metadata agent
###
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip controller_vip
#openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret teamsun
###
##  config neutron api-paste.ini
###
openstack-config --set /etc/neutron/api-paste.ini "filter:authtoken" identity_uri "http://controller_vip:35357"
openstack-config --set /etc/neutron/api-paste.ini "filter:authtoken" auth_uri "http://controller_vip:5000/v2.0"
