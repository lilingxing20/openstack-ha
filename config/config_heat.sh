#!/bin/bash
###
##  config heat
###
#openstack-config --set /etc/heat/heat.conf DEFAULT trusts_delegated_roles heat_stack_owner
openstack-config --set /etc/heat/heat.conf DEFAULT heat_metadata_server_url http://controller_vip:8000
openstack-config --set /etc/heat/heat.conf DEFAULT heat_waitcondition_server_url http://controller_vip:8000/v1/waitcondition
openstack-config --set /etc/heat/heat.conf DEFAULT heat_watch_server_url http://controller_vip:8003
#openstack-config --set /etc/heat/heat.conf DEFAULT stack_user_domain_name heat
#openstack-config --set /etc/heat/heat.conf DEFAULT stack_domain_admin heat_admin
#openstack-config --set /etc/heat/heat.conf DEFAULT stack_domain_admin_password teamsun
#openstack-config --set /etc/heat/heat.conf DEFAULT auth_encryption_key f20dfec8879248ea
#openstack-config --set /etc/heat/heat.conf DEFAULT rpc_backend rabbit
#openstack-config --set /etc/heat/heat.conf DEFAULT log_dir /var/log/heat
openstack-config --set /etc/heat/heat.conf DEFAULT notification_driver messaging
## clients_keystone
openstack-config --set /etc/heat/heat.conf clients_keystone auth_uri http://controller_vip:35357
## database
openstack-config --set /etc/heat/heat.conf database connection mysql+pymysql://heat:teamsun@controller_vip/heat
## ec2authtoken
openstack-config --set /etc/heat/heat.conf ec2authtoken auth_uri http://controller_vip:5000/v2.0
## heat_api
openstack-config --set /etc/heat/heat.conf heat_api bind_host $(hostname -i)
openstack-config --set /etc/heat/heat.conf heat_api workers 0
## heat_api_cfn
openstack-config --set /etc/heat/heat.conf heat_api_cfn bind_host $(hostname -i)
openstack-config --set /etc/heat/heat.conf heat_api_cfn workers 0
## heat_api_cloudwatch
openstack-config --set /etc/heat/heat.conf heat_api_cloudwatch bind_host $(hostname -i)
openstack-config --set /etc/heat/heat.conf heat_api_cloudwatch workers 0
## authtoken
openstack-config --set /etc/heat/heat.conf keystone_authtoken auth_uri http://controller_vip:5000/v2.0
openstack-config --set /etc/heat/heat.conf keystone_authtoken identity_uri http://controller_vip:35357
#openstack-config --set /etc/heat/heat.conf keystone_authtoken admin_user heat
#openstack-config --set /etc/heat/heat.conf keystone_authtoken admin_tenant_name services
#openstack-config --set /etc/heat/heat.conf keystone_authtoken admin_password teamsun
## rabbit
openstack-config --del /etc/heat/heat.conf oslo_messaging_rabbit rabbit_host
openstack-config --set /etc/heat/heat.conf oslo_messaging_rabbit rabbit_hosts ha1,ha2,ha3
openstack-config --set /etc/heat/heat.conf oslo_messaging_rabbit rabbit_ha_queues True
openstack-config --set /etc/heat/heat.conf oslo_messaging_rabbit heartbeat_timeout_threshold 60
## trustee
#openstack-config --set /etc/heat/heat.conf trustee auth_plugin password
openstack-config --set /etc/heat/heat.conf trustee auth_url http://controller_vip:35357
#openstack-config --set /etc/heat/heat.conf trustee project_domain_id Default
#openstack-config --set /etc/heat/heat.conf trustee username heat
#openstack-config --set /etc/heat/heat.conf trustee user_domain_id Default
#openstack-config --set /etc/heat/heat.conf trustee password teamsun

