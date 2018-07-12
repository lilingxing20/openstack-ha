
pcs resource create haproxy systemd:haproxy op start interval=0s timeout=200s stop interval=0s timeout=200s monitor interval=60s --clone
pcs constraint order start control_vip  then start haproxy-clone  option kind=Optional
pcs constraint order start public_vip  then start haproxy-clone  option kind=Optional
pcs constraint colocation add control_vip with haproxy-clone INFINITY
pcs constraint colocation add public_vip with haproxy-clone INFINITY
