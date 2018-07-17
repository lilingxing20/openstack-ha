#!/bin/bash
SCRIPTS_DIR=$(cd $(dirname "$0") && pwd)

if [ ! -f "$1" ]; then
    echo -e "\nNeed node env file: "$(ls $SCRIPTS_DIR/node_env/)"\n"
    exit 1
fi

source $1

if [ -z "$NODE_ARRAY" ]; then
    echo -e "\nThe NODE_ARRAY is null, please check file: $1\n"
    exit 1
fi

net_type_arr=($(echo ${NODE_ARRAY}| awk '{print $NF}' | awk -F ";" '{for(i=1;i<=NF;i++){print $i}}'|awk -F ',' '{print $1}'))
net_num=${#net_type_arr[@]}

# NODE_ARRAY need in $1
NODE_NUM=$((${#NODE_ARRAY[@]}-1))
node_control_ip_arr=()
for idx in $(seq "$NODE_NUM"); do
    # echo "node: $idx"
    host_name=$(echo ${NODE_ARRAY[$idx]}| awk '{print $2}')
    net_arr=($(echo ${NODE_ARRAY[$idx]}| awk '{print $NF}' | awk -F ";" '{for(i=1;i<=NF;i++){print $i}}'|awk -F ',' '{print $1}'))
    # echo ${net_arr[*]}
    for i in $(seq 0 "$(($net_num-1))"); do 
        if [[ "${net_type_arr[$i]}" =~ control.* ]]; then
            if [ -z "$node_control_ip_arr" ]; then
                node_control_ip_arr=(${net_arr[$i]})
            else
                node_control_ip_arr=(${node_control_ip_arr[@]} ${net_arr[$i]})
            fi
            break
        fi
    done
done

echo ${node_control_ip_arr[*]}

SSH_CMD='ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null '


## config puppet
for node in ${node_control_ip_arr[*]}; do
    echo $node
    # yaml_file="controller_pacemaker"
    yaml_file="controller_$node"
    $SSH_CMD $node "echo '---
:backends:
  - yaml
:hierarchy:
  - $yaml_file
:yaml:
  :datadir: /var/tmp/ocata/hieradata
' >/etc/puppet/hiera.yaml
" &
done
wait


## ceph client
if [[ "$2" == "ceph" ]]; then
for ii in 0 2; do
    echo "ceph client step: $ii"
    for node in ${node_control_ip_arr[*]}; do
        yaml_file="controller_$node"
        $SSH_CMD $node "puppet --version
sed -i  's/^step: .*/step: ${ii}/' /var/tmp/ocata/hieradata/${yaml_file}.yaml
puppet apply --modulepath=/var/tmp/ocata/puppet/modules/ /var/tmp/ocata/manifests/ceph_client.pp -d --logdest /var/log/puppet/aplly_ceph_client_${ii}_$(date "+%Y_%m_%d_%H_%M_%S").log
" &
    done
    wait
    sleep 5
done
fi


## controller use pacemaker
for ii in $(seq 0 5); do
    echo "controller step: $ii"
    for node in ${node_control_ip_arr[*]}; do
        yaml_file="controller_$node"
        $SSH_CMD $node "puppet --version
sed -i  's/^step: .*/step: ${ii}/' /var/tmp/ocata/hieradata/${yaml_file}.yaml
puppet apply --modulepath=/var/tmp/ocata/puppet/modules/ /var/tmp/ocata/manifests/overcloud_controller_pacemaker.pp -d --logdest /var/log/puppet/aplly_controller_${ii}_$(date "+%Y_%m_%d_%H_%M_%S").log
" &
    done
    wait
    sleep 5
done


# vim: tabstop=4 shiftwidth=4 softtabstop=4
