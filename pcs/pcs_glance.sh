pcs resource create openstack-glance-api systemd:openstack-glance-api op monitor start-delay=10s --clone interleave=true
pcs resource create openstack-glance-registry systemd:openstack-glance-registry op monitor start-delay=10s --clone interleave=true

pcs constraint order start openstack-core-clone then start openstack-glance-registry-clone option kind=Mandatory
pcs constraint order start openstack-glance-registry-clone then start openstack-glance-api-clone option kind=Mandatory

pcs constraint colocation add openstack-glance-api-clone with openstack-glance-registry-clone INFINITY

