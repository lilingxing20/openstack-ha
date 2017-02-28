
pcs resource create rabbitmq rabbitmq-cluster set_policy='ha-all ^(?!amq\.).* {"ha-mode":"all"}' meta notify=true ordered=true interleave=true --clone

pcs constraint order start rabbitmq-clone then start openstack-core-clone option kind=Mandatory
