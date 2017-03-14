exit 0
##
mkdir -p --mode=0750 /etc/pacemaker/
dd if=/dev/urandom of=/etc/pacemaker/authkey bs=4096 count=1
chgrp haclient /etc/pacemaker
chown root:haclient /etc/pacemaker/authkey
rsync -av /etc/pacemaker controller1:/etc/
rsync -av /etc/pacemaker controller2:/etc/
rsync -av /etc/pacemaker controller3:/etc/

##
pcs config | grep systemd | awk '{print $2}' | while read RESOURCE; do pcs resource update $RESOURCE op start timeout=200s op stop timeout=200s; done

source openrc_admin
pcs resource create nova-evacuate ocf:openstack:NovaEvacuate auth_url=$OS_AUTH_URL username=$OS_USERNAME password=$OS_PASSWORD tenant_name=$OS_TENANT_NAME domain=localdomain op start timeout=300 monitor interval=10 timeout=600
 --clone interleave=true --disabled --force
pcs resource create nova-compute-checkevacuate ocf:openstack:nova-compute-wait auth_url=$OS_AUTH_URL username=$OS_USERNAME password=$OS_PASSWORD tenant_name=$OS_TENANT_NAME domain=localdomain op start timeout=300 --clone interleave=true --disabled --force

pcs constraint order start haproxy-clone then nova-evacuate
pcs constraint order start galera-clone then nova-evacuate
pcs constraint order start rabbitmq-clone then nova-evacuate
for i in openstack-glance-api-clone neutron-metadata-agent-clone openstack-nova-conductor-clone; do pcs constraint order start $i then nova-evacuate require-all=false ; done


all_nodes=$(cibadmin -Q -o nodes | grep uname | sed s/.*uname..// | awk -F\" '{print $1}')
controllers=$(cibadmin -Q -o nodes | grep uname | grep -v remote | sed s/.*uname..// | awk -F\" '{print $1}')
computers=$(cibadmin -Q -o nodes | grep uname | grep remote | sed s/.*uname..// | awk -F\" '{print $1}')
for controller in ${controllers}; do sudo pcs property set --node ${controller} osprole=controller ; done
for computer in ${computers}; do sudo pcs property set --node ${computer} osprole=compute ; done


for i in $(cibadmin -Q --xpath //primitive --node-path | tr ' ' '\n' | awk -F "id='" '{print $2}' | awk -F "'" '{print $1}' | uniq); do pcs constraint location $i rule resource-discovery=exclusive score=0 osprole eq controller; done


## neutron-openvswitch-agent-compute
pcs resource create neutron-openvswitch-agent-compute systemd:neutron-openvswitch-agent op start interval=0s timeout=200s stop interval=0s timeout=200s monitor interval=60s --clone interleave=true --disabled --force
pcs constraint location neutron-openvswitch-agent-compute-clone rule resource-discovery=exclusive score=0 osprole eq compute
pcs constraint order start neutron-server-clone then neutron-openvswitch-agent-compute-clone require-all=false

## libvert
pcs resource create libvirtd-compute systemd:libvirtd --clone interleave=true --disabled --force
pcs constraint location libvirtd-compute-clone rule resource-discovery=exclusive score=0 osprole eq compute
pcs constraint order start neutron-openvswitch-agent-compute-clone then libvirtd-compute-clone
pcs constraint colocation add libvirtd-compute-clone with neutron-openvswitch-agent-compute-clone

## nova-compute
source openrc_admin
pcs resource create nova-compute-checkevacuate ocf:openstack:nova-compute-wait auth_url=$OS_AUTH_URL username=$OS_USERNAME password=$OS_PASSWORD tenant_name=$OS_TENANT_NAME domain=localdomain op start timeout=300 --clone interleave=true --disabled --force
pcs constraint location nova-compute-checkevacuate-clone rule resource-discovery=exclusive score=0 osprole eq compute
pcs constraint order start openstack-nova-conductor-clone then nova-compute-checkevacuate-clone require-all=false
pcs resource create nova-compute systemd:openstack-nova-compute --clone interleave=true --disabled --force
pcs constraint location nova-compute-clone rule resource-discovery=exclusive score=0 osprole eq compute
pcs constraint order start nova-compute-checkevacuate-clone then nova-compute-clone require-all=true
pcs constraint order start nova-compute-clone then nova-evacuate require-all=false
pcs constraint order start libvirtd-compute-clone then nova-compute-clone
pcs constraint colocation add nova-compute-clone with libvirtd-compute-clone


创建一个独立fence-nova stonith装置:
pcs stonith create ipmilan-computer-200 fence_ipmilan pcmk_host_list=computer200 ipaddr=172.30.240.8 login=root passwd=calvin lanplus=1 cipher=1 op monitor interval=60s
pcs stonith create ipmilan-computer-201 fence_ipmilan pcmk_host_list=computer201 ipaddr=172.30.240.18 login=root passwd=calvin lanplus=1 cipher=1 op monitor interval=60s

pcs property set cluster-recheck-interval=1min

pcs resource create computer200 ocf:pacemaker:remote reconnect_interval=60 op monitor interval=20
pcs resource create computer201 ocf:pacemaker:remote reconnect_interval=60 op monitor interval=20

pcs property set --node computer201 osprole=compute
pcs property set --node computer201 osprole=compute

pcs stonith level add 1 computer200 ipmilan-computer-200,fence-nova
pcs stonith level add 1 computer201 ipmilan-computer-201,fence-nova
pcs stonith level
pcs stonith
pcs property set stonith-enabled=true


