#!/bin/bash

echo "This script checks CPU usage from VMs."
echo "You have to launch it directly on a nova compute..."
echo "It will install libvirt-clients..."
echo "Please use \`cur_openstack_usage.sh\` script instead of this one."


read -p 'Continue anyway ? [YyNn]' continue

if [[ "${continue}" == [Yy]* ]]; then 
    sudo apt-get install -y libvirt-clients
    CPU_TOTAL=$(lscpu |awk  '/^CPU\(s\):/ {print $2}')
    # vcpu.current or vcpu.maximum ?
    CPU_CURR_MAXUSED=$(virsh domstats --list-active --vcpu | awk -F= 'BEGIN{total=0;} {if ($1 ~ "maximum") {total+=$2;}}; END{print total;}')
    USAGE=$(echo "${CPU_CURR_MAXUSED}/${CPU_TOTAL}" |bc -l)
    echo $USAGE
fi
