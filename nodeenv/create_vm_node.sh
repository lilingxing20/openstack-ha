#!/bin/bash

SCRIPTS_DIR=$(cd $(dirname "$0") && pwd)

if [ ! -f "$1" ]; then
    echo -e "\nNeed node env file: "$(ls $SCRIPTS_DIR/scene/)"\n"
    exit 1
fi

source $1

if [ -z "$NODE_ARRAY" ]; then
    echo -e "\nThe NODE_ARRAY is null, please check file: $1\n"
    exit 1
fi

# NODE_ARRAY need in $1
NODE_NUM=$((${#NODE_ARRAY[@]}-1))

ENV_NAME=$(basename $1)
VM_BOOT_DIR="${SCRIPTS_DIR}/run/image/${ENV_NAME}"
TMP_DIR="${SCRIPTS_DIR}/run/${ENV_NAME}"
ETC_HOSTS_FILE="${SCRIPTS_DIR}/run/${ENV_NAME}_hosts"

REPO_FILE="${SCRIPTS_DIR}/repo/ocataCentOS74.x86_64.repo"
BASE_IMAGE="${SCRIPTS_DIR}/image/centos74.qcow2"

# check base image
if [ ! -f $BASE_IMAGE ]; then
    echo "Please check: $BASE_IMAGE"
    exit 1
fi

# init env dir
test -f $ETC_HOSTS_FILE && exit 0
test -d $VM_BOOT_DIR || mkdir -pv $VM_BOOT_DIR
test -d $TMP_DIR || mkdir -pv $TMP_DIR

# make etc hosts
net_type_arr=($(echo ${NODE_ARRAY}| awk '{print $NF}' | awk -F ";" '{for(i=1;i<=NF;i++){print $i}}'|awk -F ',' '{print $1}'))
echo ${net_type_arr[*]}
net_num=${#net_type_arr[@]}
cat >$ETC_HOSTS_FILE <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
EOF
for idx in $(seq "$NODE_NUM"); do
    echo "node: $idx"
    host_name=$(echo ${NODE_ARRAY[$idx]}| awk '{print $2}')
    net_arr=($(echo ${NODE_ARRAY[$idx]}| awk '{print $NF}' | awk -F ";" '{for(i=1;i<=NF;i++){print $i}}'|awk -F ',' '{print $1}'))
    echo ${net_arr[*]}
    for i in $(seq 0 "$(($net_num-1))"); do 
        echo -e "${net_arr[$i]}\t${host_name}-${net_type_arr[$i]}" >>$ETC_HOSTS_FILE
        [[ "${net_type_arr[$i]}" =~ control.* ]] && echo -e "${net_arr[$i]}\t${host_name}" >>$ETC_HOSTS_FILE
    done
done

# make node
for idx in $(seq "$NODE_NUM"); do
echo "$idx"
echo ${NODE_ARRAY[$idx]} | while read  vm_name host_name vm_nets; do

    vm_boot_disk=$VM_BOOT_DIR/${vm_name}.qcow2
    vm_mount_dir=${TMP_DIR}/${vm_name}/
    
    # copy vm image
    cp -v $BASE_IMAGE ${vm_boot_disk}
    
    # mount image
    test -d ${vm_mount_dir} || mkdir -p ${vm_mount_dir}
    guestmount -a $vm_boot_disk -m /dev/centos/root --rw ${vm_mount_dir}
    
    # create network eth* file
    ${SCRIPTS_DIR}/libs/create_eth.sh "config_vm_eth $vm_mount_dir $vm_nets"
    
    # add repo
    mkdir -pv ${vm_mount_dir}etc/yum.repos.d/bak
    mv ${vm_mount_dir}etc/yum.repos.d/*.repo ${vm_mount_dir}etc/yum.repos.d/bak/
    test -f ${REPO_FILE} && cp -v ${REPO_FILE} ${vm_mount_dir}etc/yum.repos.d/
    
    # hostname
    echo "${host_name}" > ${vm_mount_dir}etc/hostname
    
    # hosts
    rm -vf ${vm_mount_dir}etc/hosts
    cp -v $ETC_HOSTS_FILE ${vm_mount_dir}etc/hosts
    
    # authorized_keys
    newvm_ssh_dir=${vm_mount_dir}root/.ssh/
    test -d ${newvm_ssh_dir} || mkdir -m 700 ${newvm_ssh_dir}
    test -f "$HOME/.ssh/id_rsa.pub" || ssh-keygen -f $HOME/.ssh/id_rsa -N ""
    cat $HOME/.ssh/id_rsa.pub >> ${newvm_ssh_dir}/authorized_keys
    chmod 600 ${newvm_ssh_dir}/authorized_keys

    #umount image
    guestunmount ${vm_mount_dir}
    test -d ${vm_mount_dir} && rmdir ${vm_mount_dir}

    # boot vm
    ${SCRIPTS_DIR}/libs/boot_vm.sh "boot_vm $vm_name $vm_boot_disk"

    sleep 5
done
done

test -d $TMP_DIR && rmdir -v $TMP_DIR

# vim: tabstop=4 shiftwidth=4 softtabstop=4
