pcs resource create neutron-server systemd:neutron-server meta interleave=true op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create neutron-openvswitch-agent systemd:neutron-openvswitch-agent meta interleave=true op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create neutron-dhcp-agent systemd:neutron-dhcp-agent meta interleave=true op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create neutron-metadata-agent systemd:neutron-metadata-agent meta interleave=true op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create neutron-l3-agent systemd:neutron-l3-agent meta interleave=true op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create neutron-metering-agent systemd:neutron-metering-agent meta interleave=true op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create neutron-ovs-cleanup systemd:neutron-ovs-cleanup meta interleave=true op monitor interval=10s timeout=20 start interval=0s timeout=40s stop interval=0s timeout=300s --clone
pcs resource create neutron-netns-cleanup systemd:neutron-netns-cleanup meta interleave=true op monitor interval=10s timeout=20 start interval=0s timeout=40s stop interval=0s timeout=300s --clone

pcs constraint order start openstack-core-clone then start neutron-server-clone
pcs constraint order start neutron-server-clone then start neutron-openvswitch-agent-clone
pcs constraint order start neutron-openvswitch-agent-clone then start neutron-dhcp-agent-clone
pcs constraint order start neutron-dhcp-agent-clone then start neutron-l3-agent-clone
pcs constraint order start neutron-l3-agent-clone then start neutron-metadata-agent-clone
pcs constraint order start neutron-ovs-cleanup-clone then start neutron-netns-cleanup-clone
pcs constraint order start neutron-netns-cleanup-clone then start neutron-openvswitch-agent-clone

pcs constraint colocation add neutron-metadata-agent-clone with neutron-l3-agent-clone INFINITY
pcs constraint colocation add neutron-l3-agent-clone with neutron-dhcp-agent-clone INFINITY
pcs constraint colocation add neutron-dhcp-agent-clone with neutron-openvswitch-agent-clone INFINITY
pcs constraint colocation add neutron-openvswitch-agent-clone with neutron-netns-cleanup-clone INFINITY
pcs constraint colocation add neutron-netns-cleanup-clone with neutron-ovs-cleanup-clone INFINITY


