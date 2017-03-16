rm -f account.builder container.builder object.builder
rm -f account.ring.gz container.ring.gz object.ring.gz
rm -rf backups/

swift-ring-builder account.builder create 18 3 1
swift-ring-builder container.builder create 18 3 1
swift-ring-builder object.builder create 18 3 1

swift-ring-builder account.builder add --region 1 --zone 1 --ip controller1-internalapi --port 6002 --device sdb --weight 20
swift-ring-builder account.builder add --region 1 --zone 2 --ip controller1-internalapi --port 6002 --device sdc --weight 10
swift-ring-builder account.builder add --region 2 --zone 3 --ip controller2-internalapi --port 6002 --device sdb --weight 20
swift-ring-builder account.builder add --region 2 --zone 4 --ip controller2-internalapi --port 6002 --device sdc --weight 10
#swift-ring-builder account.builder add --region 3 --zone 5 --ip controller3-internalapi --port 6002 --device sdd --weight 20
#swift-ring-builder account.builder add --region 3 --zone 6 --ip controller3-internalapi --port 6002 --device sdc --weight 10
swift-ring-builder account.builder
swift-ring-builder container.builder add --region 1 --zone 1 --ip controller1-internalapi --port 6001 --device sdb --weight 20
swift-ring-builder container.builder add --region 1 --zone 2 --ip controller1-internalapi --port 6001 --device sdc --weight 10
swift-ring-builder container.builder add --region 2 --zone 3 --ip controller2-internalapi --port 6001 --device sdb --weight 20
swift-ring-builder container.builder add --region 2 --zone 4 --ip controller2-internalapi --port 6001 --device sdc --weight 10
#swift-ring-builder container.builder add --region 3 --zone 5 --ip controller3-internalapi --port 6001 --device sdd --weight 20
#swift-ring-builder container.builder add --region 3 --zone 6 --ip controller3-internalapi --port 6001 --device sdc --weight 10
swift-ring-builder container.builder
swift-ring-builder object.builder add --region 1 --zone 1 --ip controller1-internalapi --port 6000 --device sdb --weight 20
swift-ring-builder object.builder add --region 1 --zone 2 --ip controller1-internalapi --port 6000 --device sdc --weight 10
swift-ring-builder object.builder add --region 2 --zone 3 --ip controller2-internalapi --port 6000 --device sdb --weight 20
swift-ring-builder object.builder add --region 2 --zone 4 --ip controller2-internalapi --port 6000 --device sdc --weight 10
#swift-ring-builder object.builder add --region 3 --zone 5 --ip controller3-internalapi --port 6000 --device sdd --weight 20
#swift-ring-builder object.builder add --region 3 --zone 6 --ip controller3-internalapi --port 6000 --device sdc --weight 10
swift-ring-builder object.builder

#swift-ring-builder account.builder add r1z1-172.16.0.13:6002/sdb 20
#swift-ring-builder account.builder add r1z2-172.16.0.13:6002/sdc 10
#swift-ring-builder account.builder add r2z3-172.16.0.14:6002/sdb 20
#swift-ring-builder account.builder add r2z4-172.16.0.14:6002/sdc 10
#swift-ring-builder account.builder add r3z5-172.16.0.15:6002/sdd 20
#swift-ring-builder account.builder add r3z6-172.16.0.15:6002/sdc 10
#swift-ring-builder account.builder
#swift-ring-builder container.builder add r1z1-172.16.0.13:6001/sdb 20
#swift-ring-builder container.builder add r1z2-172.16.0.13:6001/sdc 10
#swift-ring-builder container.builder add r2z3-172.16.0.14:6001/sdb 20
#swift-ring-builder container.builder add r2z4-172.16.0.14:6001/sdc 10
#swift-ring-builder container.builder add r3z5-172.16.0.15:6001/sdd 20
#swift-ring-builder container.builder add r3z6-172.16.0.15:6001/sdc 10
#swift-ring-builder container.builder
#swift-ring-builder object.builder add r1z1-172.16.0.13:6000/sdb 20
#swift-ring-builder object.builder add r1z2-172.16.0.13:6000/sdc 10
#swift-ring-builder object.builder add r2z3-172.16.0.14:6000/sdb 20
#swift-ring-builder object.builder add r2z4-172.16.0.14:6000/sdc 10
#swift-ring-builder object.builder add r3z5-172.16.0.15:6000/sdd 20
#swift-ring-builder object.builder add r3z6-172.16.0.15:6000/sdc 10
#swift-ring-builder object.builder


swift-ring-builder account.builder rebalance
swift-ring-builder container.builder rebalance
swift-ring-builder object.builder rebalance
