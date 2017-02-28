pcs resource create openstack-glance-api systemd:openstack-glance-api meta interleave=true op monitor start-delay=10s --clone
pcs resource create openstack-glance-registry systemd:openstack-glance-registry meta interleave=true op monitor start-delay=10s --clone

pcs constraint order start openstack-core-clone then start openstack-glance-registry-clone option kind=Mandatory
pcs constraint order start openstack-glance-registry-clone then start openstack-glance-api-clone option kind=Mandatory

pcs constraint colocation add openstack-glance-api-clone with openstack-glance-registry-clone INFINITY

