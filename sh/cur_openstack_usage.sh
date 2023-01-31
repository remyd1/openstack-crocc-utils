#!/bin/bash
#
#

set -e

usage="$0 [-p] [hypervisor|--fip]\n
  [hypervisor name] is optional. Without it, it will retrieve the current load of all the hypervisors.\n
  [--fip] This option will retrieve the current status of your FIP network. Edit this script to change PUB_NETWORK name. Default is 'public1'\n
  [-h | --help] print this help and exit\n
  [-p] show usage % with a progress bar\n
\n\n
  You have to source an admin credential file of OpenStack to be able to use this piece of code.\n
  You also need the openstack client, awk and bc.\n
"

PUB_NETWORK="public1"

_OPENSTACK=`command -v openstack`
_AWK=`command -v awk`
_BC=`command -v bc`

PROGRESS=0

if [[ "${1}" == "-p" ]]; then
  PROGRESS=1
  shift
fi

compute=${1}

compute_fields=("service_host" "state" "status" "running_vms" "vcpus_used" "vcpus" "memory_mb_used" "memory_mb" "local_gb_used" "local_gb" "hypervisor_version")
ip_fields=("network_name" "used_ips" "total_ips")
compute_filter=""

for f in ${compute_fields[@]}; do 
  compute_filter=`echo "${compute_filter} -c ${f}"`
done

print_usage() {
  LOAD=`${_OPENSTACK} hypervisor show ${1} -f yaml $(echo -n ${compute_filter})`
  LOAD=`echo "${LOAD}"| tr '\n' ','`
  readarray -td, load_array <<< ${LOAD};# declare -p load_array
  for val in "${load_array[@]}"
  do
    echo ${val}
    if [[ "${val}" =~ "vcpus" ]]; then
      if [[ "${val}" =~ "used" ]]; then
        vcpus_used=$(echo ${val} | ${_AWK} '{if ($1 ~ "vcpus_used") {print $2}}')
      else
        vcpus_total=$( echo ${val} | ${_AWK} '{if ($1 == "vcpus:") {print $2}}' )
      fi
    fi
    if [[ "${val}" =~ "memory" ]]; then
      if [[ "${val}" =~ "used" ]]; then
        memory_used=$( echo ${val} | ${_AWK} '{if ($1 ~ "memory_mb_used") {print $2}}' )
      else
        memory_total=$( echo ${val} | ${_AWK} '{if ($1 == "memory_mb:") {print $2}}' )
      fi
    fi
    if [[ "${val}" =~ "local_gb" ]]; then
      if [[ "${val}" =~ "used" ]]; then
        gb_used=$( echo ${val} | ${_AWK} '{if ($1 ~ "local_gb_used") {print $2}}' )
      else
        gb_total=$( echo ${val} | ${_AWK} '{if ($1 == "local_gb:") {print $2}}' )
      fi
    fi
  done
  echo -e "\n% usage..."
  load_memory=$( echo "scale=2; ${memory_used} / ${memory_total}" | ${_BC} )
  load_vcpus=$( echo "scale=2; ${vcpus_used} / ${vcpus_total}" | ${_BC} )
  load_storage=$( echo "scale=2; ${gb_used} / ${gb_total}" | ${_BC} )
  if [ ${PROGRESS} -eq 1 ]; then
    echo "vcpu % usage:"
    progress_bar ${load_vcpus}
    echo "memory % usage:"
    progress_bar ${load_memory}
    echo "storage % usage:"
    progress_bar ${load_storage}
  else
    echo "vcpu % usage: "${load_vcpus}
    echo "memory % usage: "${load_memory}
    echo "storage % usage: "${load_storage}
  fi
}

progress_bar() {
  echo -n "["
  m=$(echo "${1}*100" | ${_BC}) #"scale=0;" does not seem to work here.
  m=${m%.*} # removing ".00" from $m
  n=$((100-${m}))
  for i in `seq 0 ${m}`; do echo -n "#"; done
  for j in `seq 0 ${n}`; do echo -n " "; done
  echo -n "]"
  echo -n "$m %"
  echo
}


if [ -z ${compute} ]; then
  HYPERVISORS=`${_OPENSTACK} hypervisor list -f yaml -c "Hypervisor Hostname" |awk '{print $NF}'`
  for compute in ${HYPERVISORS};
  do
    echo -e "\n///////////////// ${compute} /////////////////\n"
    print_usage $compute
  done
elif [[ "${compute}" =~ "--help" ]] || [[ "${compute}" =~ "-h" ]]; then
  echo -e ${usage}
  exit 1
elif [[ "${compute}" == "--fip" ]];then
  for f in ${ip_fields[@]}; do 
    ip_filter=`echo "${ip_filter} -c ${f}"`
  done
  fip_list=`${_OPENSTACK} ip availability show ${PUB_NETWORK} -f yaml ${ip_filter} 2>/dev/null`
  total_fips=$(echo ${fip_list} | ${_AWK} '{print $4}')
  used_fips=$(echo ${fip_list} | ${_AWK} '{print $6}')
  load_fips=$(echo "scale=2; ${used_fips} / ${total_fips}" | ${_BC})
  echo ${fip_list}
  if [ ${PROGRESS} -eq 1 ]; then
    echo "FIP % usage:"
    progress_bar ${load_fips}
  else
    echo "FIP load: ${load_fips} %"
  fi
else
  print_usage $compute
fi
