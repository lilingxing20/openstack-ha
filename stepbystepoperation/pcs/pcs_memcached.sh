
pcs resource create openstack-core ocf:heartbeat:Dummy meta interleave=true op start interval=0s timeout=20 stop interval=0s timeout=20 monitor interval=10 timeout=20  --clone
pcs resource create memcached systemd:memcached meta interleave=true op start interval=0s timeout=200s stop interval=0s timeout=200s monitor interval=60s --clone

pcs constraint order start memcached-clone then start openstack-core-clone option kind=Mandatory
