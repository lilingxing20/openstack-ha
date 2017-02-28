
pcs resource create galera galera additional_parameters='--open-files-limit=16384' enable_creation=true wsrep_cluster_address="gcomm://ha1,ha2,ha3"  meta master-max=3 ordered=true op promote timeout=300s on-fail=block --master

pcs constraint order promote galera-master then start openstack-core-clone option kind=Mandatory

