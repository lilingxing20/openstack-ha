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

SSH_CMD='ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
RSYNC_CMD='rsync -avz --progress -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

yaml_file='ceph'
## install puppet
for node in ${node_control_ip_arr[*]}; do
   echo $node
   $SSH_CMD $node "yum clean all
yum makecache
yum install -y puppet rsync vim
" &
done
wait


## copy puppet script
for node in ${node_control_ip_arr[*]}; do
   echo $node
   # rsync -avz --progress -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" -av /home/lixx/openstackha/openstack/ocata $node:/var/tmp/ >/dev/null &
   rsync -az -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" -av /home/lixx/openstackha/openstack/ocata $node:/var/tmp/ &
done
wait


# vim: tabstop=4 shiftwidth=4 softtabstop=4
