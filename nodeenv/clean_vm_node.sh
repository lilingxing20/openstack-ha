#!/bin/bash

SCRIPTS_DIR=$(cd $(dirname "$0") && pwd)

if [ ! -f "$1" ]; then
    echo ""
    echo "Need node env file: "$(ls $SCRIPTS_DIR/scene/)
    echo ""
    exit 1
fi

source $1

# NODE_ARRAY need in $1
NODE_NUM=$((${#NODE_ARRAY[@]}-1))

ENV_NAME=$(basename $1)
VM_BOOT_DIR="${SCRIPTS_DIR}/run/image/${ENV_NAME}"
ETC_HOSTS_FILE="${SCRIPTS_DIR}/run/${ENV_NAME}_hosts"
TMP_DIR="${SCRIPTS_DIR}/run/${ENV_NAME}"

for idx in $(seq "$NODE_NUM"); do
echo "$idx"
echo ${NODE_ARRAY[$idx]} | while read  vm_name host_name vm_nets; do
    virsh destroy $vm_name
    virsh undefine $vm_name
    vm_boot_disk=$VM_BOOT_DIR/${vm_name}.qcow2
    test -f $vm_boot_disk && rm -fv $vm_boot_disk
    ls /image/pool/ |grep $vm_name |while read vol; do virsh vol-delete --pool volpool $vol; done
done
done

test -f $ETC_HOSTS_FILE && rm -fv $ETC_HOSTS_FILE
test -d $VM_BOOT_DIR && rmdir -v $VM_BOOT_DIR

# vim: tabstop=4 shiftwidth=4 softtabstop=4
