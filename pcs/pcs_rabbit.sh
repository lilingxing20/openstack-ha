
pcs resource create rabbitmq rabbitmq-cluster set_policy='ha-all ^(?!amq\.).* {"ha-mode":"all"}' meta notify=true --clone ordered=true interleave=true

pcs constraint order start rabbitmq-clone then start openstack-core-clone option kind=Mandatory
