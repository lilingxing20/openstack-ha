
pcs resource create openstack-cinder-api systemd:openstack-cinder-api meta interleave=true op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-cinder-scheduler systemd:openstack-cinder-scheduler meta interleave=true op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-cinder-volume systemd:openstack-cinder-volume op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s

pcs constraint order start openstack-core-clone then start openstack-cinder-api-clone
pcs constraint order start openstack-cinder-api-clone then start openstack-cinder-scheduler-clone
pcs constraint order start openstack-cinder-scheduler-clone then start openstack-cinder-volume

pcs constraint colocation add openstack-cinder-scheduler-clone with openstack-cinder-api-clone INFINITY
pcs constraint colocation add openstack-cinder-volume with openstack-cinder-scheduler-clone INFINITY

