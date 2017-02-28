pcs resource create openstack-swift-container-replicator systemd:openstack-swift-container-replicator op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-container-auditor systemd:openstack-swift-container-auditor op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-container systemd:openstack-swift-container op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-object-expirer systemd:openstack-swift-object-expirer op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-proxy systemd:openstack-swift-proxy op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-account-reaper systemd:openstack-swift-account-reaper op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-account-replicator systemd:openstack-swift-account-replicator op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-account-auditor systemd:openstack-swift-account-auditor op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-account systemd:openstack-swift-account op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-object systemd:openstack-swift-object op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-object-replicator systemd:openstack-swift-object-replicator op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-object-auditor systemd:openstack-swift-object-auditor op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-object-updater systemd:openstack-swift-object-updater op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone
pcs resource create openstack-swift-container-updater systemd:openstack-swift-container-updater op monitor interval=60s start interval=0s timeout=200s stop interval=0s timeout=200s --clone

