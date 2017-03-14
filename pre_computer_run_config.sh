#!/bin/bash

systemctl stop openstack-nova-compute
systemctl stop neutron-openvswitch-agent
systemctl disable openstack-nova-compute
systemctl disable neutron-openvswitch-agent

bash -x config/config_computer.sh

