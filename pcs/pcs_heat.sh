pcs resource create openstack-heat-api systemd:openstack-heat-api op start interval=0s timeout=200s stop interval=0s timeout=200s monitor interval=60s --clone interleave=true
pcs resource create openstack-heat-api-cfn systemd:openstack-heat-api-cfn op start interval=0s timeout=200s stop interval=0s timeout=200s monitor interval=60s --clone interleave=true
pcs resource create openstack-heat-api-cloudwatch systemd:openstack-heat-api-cloudwatch op start interval=0s timeout=200s stop interval=0s timeout=200s monitor interval=60s --clone interleave=true
pcs resource create openstack-heat-engine systemd:openstack-heat-engine op start interval=0s timeout=200s stop interval=0s timeout=200s monitor interval=60s --clone interleave=true

pcs constraint order start openstack-core-clone then start openstack-heat-api-clone
pcs constraint order start openstack-heat-api-clone  then start openstack-heat-api-cfn-clone
pcs constraint order start openstack-heat-api-cfn-clone  then start openstack-heat-api-cloudwatch-clone
pcs constraint order start openstack-heat-api-cloudwatch-clone  then start openstack-heat-engine-clone

pcs constraint colocation add openstack-heat-engine-clone with openstack-heat-api-cloudwatch-clone INFINITY
pcs constraint colocation add openstack-heat-api-cloudwatch-clone with openstack-heat-api-cfn-clone INFINITY
pcs constraint colocation add openstack-heat-api-cfn-clone with openstack-heat-api-clone INFINITY

