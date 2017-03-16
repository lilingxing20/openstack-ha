
pcs resource create httpd systemd:httpd  op start interval=0s timeout=200s stop interval=0s timeout=200s monitor interval=60s --clone interleave=true

pcs constraint order start openstack-core-clone then start httpd-clone option kind=Mandatory

