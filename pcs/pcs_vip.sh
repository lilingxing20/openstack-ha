
control_vip_addr=$(cat /etc/hosts | grep control_vip | awk '{print $1}')
public_vip_addr=$(cat /etc/hosts | grep control_vip | awk '{print $1}')
pcs resource create control_vip ocf:heartbeat:IPaddr2 ip=${control_vip_addr} cidr_netmask=24 op start interval=0s timeout=20s stop interval=0s timeout=20s monitor interval=10s timeout=20s
pcs resource create public_vip ocf:heartbeat:IPaddr2 ip=${public_vip_addr} cidr_netmask=24 op start interval=0s timeout=20s stop interval=0s timeout=20s monitor interval=10s timeout=20s
