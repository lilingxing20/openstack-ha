
pcs resource create haproxy systemd:haproxy op start interval=0s timeout=200s stop interval=0s timeout=200s monitor interval=60s --clone

pcs constraint order start controller_vip  then start haproxy-clone  option kind=Optional

pcs constraint colocation add controller_vip with haproxy-clone INFINITY
