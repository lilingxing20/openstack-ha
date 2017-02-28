
pcs resource create httpd systemd:httpd meta interleave=true op start interval=0s timeout=200s stop interval=0s timeout=200s monitor interval=60s --clone

pcs constraint order start openstack-core-clone then start httpd-clone option kind=Mandatory

