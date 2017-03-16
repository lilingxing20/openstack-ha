pcs resource create openstack-nova-api systemd:openstack-nova-api op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone interleave=true 
pcs resource create openstack-nova-scheduler systemd:openstack-nova-scheduler op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone interleave=true 
pcs resource create openstack-nova-conductor systemd:openstack-nova-conductor op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone interleave=true 
pcs resource create openstack-nova-consoleauth systemd:openstack-nova-consoleauth op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone interleave=true 
pcs resource create openstack-nova-novncproxy systemd:openstack-nova-novncproxy op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone interleave=true 
pcs resource create openstack-nova-cert systemd:openstack-nova-cert op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone interleave=true 

pcs constraint order start openstack-core-clone then start openstack-nova-consoleauth-clone option kind=Mandatory
pcs constraint order start openstack-nova-consoleauth-clone then start openstack-nova-novncproxy-clone  option kind=Mandatory
pcs constraint order start openstack-nova-novncproxy-clone then start openstack-nova-api-clone  option kind=Mandatory
pcs constraint order start openstack-nova-api-clone then start openstack-nova-scheduler-clone  option kind=Mandatory
pcs constraint order start openstack-nova-scheduler-clone then start openstack-nova-conductor-clone  option kind=Mandatory
pcs constraint order start openstack-nova-conductor-clone then start openstack-nova-cert-clone  option kind=Mandatory

pcs constraint colocation add openstack-nova-conductor-clone with openstack-nova-scheduler-clone INFINITY
pcs constraint colocation add openstack-nova-scheduler-clone with openstack-nova-api-clone INFINITY
pcs constraint colocation add openstack-nova-api-clone with openstack-nova-novncproxy-clone INFINITY
pcs constraint colocation add openstack-nova-novncproxy-clone with openstack-nova-consoleauth-clone INFINITY
pcs constraint colocation add openstack-nova-consoleauth-clone with openstack-nova-cert-clone INFINITY
