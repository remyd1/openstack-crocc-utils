#!/bin/bash

VERBOSE=FALSE

if [ -n "$1" ]; then
  if [[ "$1" == "-v" ]]; then
    VERBOSE=TRUE
  fi
fi

CUR_DIR="${pwd}"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [[ "${1}" == "bash" ]] || [[ "${1}" == "sh" ]] || [[ "${1}" == "zsh" ]] || [[ "${1}" == "ksh" ]]; then
	shift
fi


cd "${SCRIPT_DIR}" || exit

all_fips_with_projID=$(openstack floating ip list -c "Floating IP Address" -c Project -f value|sort -k1)
projects=$(echo "${all_fips_with_projID}"| awk '{print $2}' |sort |uniq)

echo "+------------------------------------------------------------------------------------------+"
echo "| ------- Project ID ------- | ------- Floating IP Address ------- | ------- Email ------- |"
echo "+------------------------------------------------------------------------------------------+"


for project in ${projects}; do
  CUR_FIPs=$(echo "${all_fips_with_projID}"| awk -v PROJ="${project}" '$0 ~ PROJ {print $1}')
  emails=$(openstack user list --project "${project}" --long -c Email -f value)
  for CUR_FIP in $CUR_FIPs; do
    for Email in $emails; do
      echo "| ${project} | ${CUR_FIP} | ${Email} |"
	done
  done
  echo "+------------------------------------------------------------------------------------------+"
done

cd "${CUR_DIR}" || exit