#!/bin/bash
#
#

set -ex

#################################################################
# basculer sur `openstack resource provider ....`
# openstack resource provider list
# puis
# openstack resource provider inventory list <uuid>
# ou, moins precis :
# openstack resource provider usage show <uuid>
# openstack resource provider list -c uuid -c name -f value | while read -r line ; do UUID=$(echo ${line}|cut -d ' ' -f1); NAME=$(echo ${line}|cut -d ' ' -f2); echo "${NAME}" && openstack resource provider inventory list "${UUID}"; done
#################################################################

usage="$0 [-p] [hypervisor|--fip]\n
  [--compute=<compute>|-c=<compute>] hypervisor name. Optional. Without it, it will retrieve the current load of all the hypervisors.\n
  [--fip] This option will retrieve the current status of your FIP network.\n
  [--net=<pub network>] Use this option to modify the public network name (default is 'public')\n
  [-p] show usage % with a progress bar\n
  [-h | --help] print this help and exit\n
\n\n
  You have to source an admin credential file of OpenStack to be able to use this piece of code.\n
  You also need the openstack client, awk and bc.\n
"

FIP=0
PROGRESS=0
PUB_NETWORK="public"
COMPUTE=""

for i in "$@"; do
  case $i in
    --net=*|--network=*)
      PUB_NETWORK="${i#*=}"
      shift
      ;;
    -c=*|--compute=*)
      COMPUTE="${i#*=}"
      shift
      ;;
    -p|--progress)
      PROGRESS=1
      shift # past argument=value
      ;;
    -f|--fip)
      FIP=1
      shift # past argument with no value
      ;;
    -h|--help)
      echo "${usage}"
      exit 1
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 1
      ;;
    *)
      ;;
  esac
done




_OPENSTACK=$(command -v openstack)
_AWK=$(command -v awk)
_BC=$(command -v bc)


compute_fields=("service_host" "state" "status" "running_vms" "vcpus_used" "vcpus" "memory_mb_used" "memory_mb" "local_gb_used" "local_gb" "hypervisor_version")
ip_fields=("network_name" "used_ips" "total_ips")
compute_filter=""

for f in ${compute_fields[@]}; do 
  compute_filter=$(echo "${compute_filter} -c ${f}")
done

print_usage() {
  LOAD=$(${_OPENSTACK} hypervisor show ${1} -f yaml $(echo -n ${compute_filter}))
  LOAD=$(echo "${LOAD}"| tr '\n' ',')
  readarray -td, load_array <<< ${LOAD};# declare -p load_array
  for val in "${load_array[@]}"
  do
    echo ${val}
    if [[ "${val}" =~ "state" ]]; then
      STATE_COMPUTE=$(echo ${val} | ${_AWK} '{if ($1 ~ "state") {print $2}}')
      if [[ ${STATE_COMPUTE} == "down" ]]; then
        continue
      fi
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
  for i in $(seq 0 ${m}); do echo -n "#"; done
  for j in $(seq 0 ${n}); do echo -n " "; done
  echo -n "]"
  echo -n "$m %"
  echo
}


if [ -z ${COMPUTE} ]; then
  HYPERVISORS=$(${_OPENSTACK} hypervisor list -f yaml -c "Hypervisor Hostname" |awk '{print $NF}')
  for COMPUTE in ${HYPERVISORS};
  do
    echo -e "\n///////////////// ${COMPUTE} /////////////////\n"
    print_usage $COMPUTE
  done
else
  print_usage ${COMPUTE}
fi

if [[ "${FIP}" -eq 1 ]];then
  for f in ${ip_fields[@]}; do 
    ip_filter=$(echo "${ip_filter} -c ${f}")
  done
  fip_list=$(${_OPENSTACK} ip availability show ${PUB_NETWORK} -f yaml ${ip_filter} 2>/dev/null)
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
fi
