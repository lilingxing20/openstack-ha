
pcs resource create controller_vip ocf:heartbeat:IPaddr2 ip=10.200.0.205 cidr_netmask=8 op start interval=0s timeout=20s stop interval=0s timeout=20s monitor interval=10s timeout=20s

