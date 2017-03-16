#!/bin/bash
test -f /etc/httpd/conf.d/15-horizon_vhost.conf && mv /etc/httpd/conf.d/1{5,0}-horizon_vhost.conf
sed -i "s/*:35357/$(hostname -s)-internalapi:35357/" /etc/httpd/conf.d/10-keystone_wsgi_admin.conf
sed -i "s/*:5000/$(hostname -s)-internalapi:5000/" /etc/httpd/conf.d/10-keystone_wsgi_main.conf
sed -i "s/*:80/$(hostname -s)-internalapi:80/" /etc/httpd/conf.d/10-horizon_vhost.conf

sed -i "s/*:80/$(hostname -s)-internalapi:80/" /etc/httpd/conf.d/15-default.conf

sed -i "s/Listen 80$/Listen $(hostname -s)-internalapi:80/" /etc/httpd/conf/ports.conf
sed -i "s/Listen 35357$/Listen $(hostname -s)-internalapi:35357/" /etc/httpd/conf/ports.conf
sed -i "s/Listen 5000$/Listen $(hostname -s)-internalapi:5000/" /etc/httpd/conf/ports.conf
#sed -i "s/Listen 8041$/Listen $(hostname -s)-internalapi:8041/" /etc/httpd/conf/ports.conf
#sed -i "s/Listen 8042$/Listen $(hostname -s)-internalapi:8042/" /etc/httpd/conf/ports.conf

sed -i 's/^OPENSTACK_KEYSTONE_URL.*/OPENSTACK_KEYSTONE_URL = "http:\/\/control_vip:5000\/v2.0"/' /usr/share/openstack-dashboard/openstack_dashboard/local/local_settings.py
