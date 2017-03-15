#!/bin/bash
###
##  config nova compute
###
#openstack-config --set /etc/nova/nova.conf DEFAULT  rpc_backend rabbit
#openstack-config --set /etc/nova/nova.conf DEFAULT  auth_strategy keystone
openstack-config --set /etc/nova/nova.conf DEFAULT  injected_network_template '$pybasedir/nova/virt/interfaces.template'
#openstack-config --set /etc/nova/nova.conf DEFAULT  force_snat_range 0.0.0.0/0
#openstack-config --set /etc/nova/nova.conf DEFAULT  firewall_driver nova.virt.firewall.NoopFirewallDriver
openstack-config --set /etc/nova/nova.conf DEFAULT  flat_injected true
#openstack-config --set /etc/nova/nova.conf DEFAULT  network_api_class  nova.network.neutronv2.api.API
openstack-config --set /etc/nova/nova.conf DEFAULT  force_config_drive true
openstack-config --set /etc/nova/nova.conf DEFAULT  metadata_host controller_vip
#openstack-config --set /etc/nova/nova.conf DEFAULT  security_group_api neutron
openstack-config --set /etc/nova/nova.conf DEFAULT  config_drive_format vfat
###  api database
openstack-config --set /etc/nova/nova.conf api_database  connection mysql://nova_api:teamsun@controller_vip/nova_api
###  database
openstack-config --set /etc/nova/nova.conf database  connection mysql://nova:teamsun@controller_vip/nova
###  glance
openstack-config --set /etc/nova/nova.conf glance  api_servers http://controller_vip:9292
###  libvirt
#openstack-config --set /etc/nova/nova.conf libvirt  virt_type qemu
#openstack-config --set /etc/nova/nova.conf libvirt  inject_password False
#openstack-config --set /etc/nova/nova.conf libvirt  inject_key False
#openstack-config --set /etc/nova/nova.conf libvirt  inject_partition -1
#openstack-config --set /etc/nova/nova.conf libvirt  live_migration_uri "qemu+tcp://nova@%s/system"
#openstack-config --set /etc/nova/nova.conf libvirt  cpu_mode none
#openstack-config --set /etc/nova/nova.conf libvirt  vif_driver nova.virt.libvirt.vif.LibvirtGenericVIFDriver
openstack-config --set /etc/nova/nova.conf libvirt  iscsi_use_multipath true
###  neutron
openstack-config --set /etc/nova/nova.conf neutron  url  http://controller_vip:9696
#openstack-config --set /etc/nova/nova.conf neutron  region_name RegionOne
#openstack-config --set /etc/nova/nova.conf neutron  ovs_bridge br-int
openstack-config --set /etc/nova/nova.conf neutron  auth_url http://controller_vip:35357/v3
##openstack-config --set /etc/nova/nova.conf neutron  auth_type password
#openstack-config --set /etc/nova/nova.conf neutron  auth_plugin v3password
#openstack-config --set /etc/nova/nova.conf neutron  username neutron
#openstack-config --set /etc/nova/nova.conf neutron  password teamsun
#openstack-config --set /etc/nova/nova.conf neutron  project_domain_name Default
#openstack-config --set /etc/nova/nova.conf neutron  user_domain_name Default
#openstack-config --set /etc/nova/nova.conf neutron  project_name services
##openstack-config --set /etc/nova/nova.conf neutron service_metadata_proxy True
##openstack-config --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret teamsun
###  rabbit
openstack-config --del /etc/nova/nova.conf oslo_messaging_rabbit  rabbit_host
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit  rabbit_hosts controller1,controller2,controller3
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit  rabbit_ha_queues True
###  vnc
#openstack-config --set /etc/nova/nova.conf vnc  enabled True
openstack-config --set /etc/nova/nova.conf vnc  vncserver_listen '0.0.0.0'
openstack-config --set /etc/nova/nova.conf vnc  vncserver_proxyclient_address  $(hostname)
openstack-config --set /etc/nova/nova.conf vnc  novncproxy_base_url  'http://controller_vip:6080/vnc_auto.html'
###


#!/bin/bash
###
##  config neutron.conf
###
#openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy  keystone
#openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips  True
#openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend  rabbit
#openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin  neutron.plugins.ml2.plugin.Ml2Plugin
#openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins  router,metering
###  config rabbit
openstack-config --del /etc/neutron/neutron.conf oslo_messaging_rabbit  rabbit_host
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit  rabbit_hosts controller1,controller2,controller3
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit  rabbit_ha_queues True
###
##  config neutron openvswitch_agent.ini
###
#openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings integration_bridge br-int
#openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings vlan_phy:br-vlan
#openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver neutron.agent.firewall.NoopFirewallDriver


