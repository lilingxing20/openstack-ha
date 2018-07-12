swift-ring-builder account.builder create 18 3 1
swift-ring-builder container.builder create 18 3 1
swift-ring-builder object.builder create 18 3 1

swift-ring-builder account.builder add r1z1-10.200.0.201:6002/sdb 20
swift-ring-builder account.builder add r1z2-10.200.0.201:6002/sdc 10
swift-ring-builder account.builder add r2z3-10.200.0.202:6002/sdb 20
swift-ring-builder account.builder add r2z4-10.200.0.202:6002/sdc 10
swift-ring-builder account.builder add r3z5-10.200.0.203:6002/sdd 20
swift-ring-builder account.builder add r3z6-10.200.0.203:6002/sdc 10
swift-ring-builder account.builder
swift-ring-builder container.builder add r1z1-10.200.0.201:6001/sdb 20
swift-ring-builder container.builder add r1z2-10.200.0.201:6001/sdc 10
swift-ring-builder container.builder add r2z3-10.200.0.202:6001/sdb 20
swift-ring-builder container.builder add r2z4-10.200.0.202:6001/sdc 10
swift-ring-builder container.builder add r3z5-10.200.0.203:6001/sdd 20
swift-ring-builder container.builder add r3z6-10.200.0.203:6001/sdc 10
swift-ring-builder container.builder
swift-ring-builder object.builder add r1z1-10.200.0.201:6000/sdb 20
swift-ring-builder object.builder add r1z2-10.200.0.201:6000/sdc 10
swift-ring-builder object.builder add r2z3-10.200.0.202:6000/sdb 20
swift-ring-builder object.builder add r2z4-10.200.0.202:6000/sdc 10
swift-ring-builder object.builder add r3z5-10.200.0.203:6000/sdd 20
swift-ring-builder object.builder add r3z6-10.200.0.203:6000/sdc 10
swift-ring-builder object.builder
swift-ring-builder account.builder rebalance
swift-ring-builder container.builder rebalance
swift-ring-builder object.builder rebalance

