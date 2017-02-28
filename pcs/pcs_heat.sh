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

