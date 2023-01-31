#!/bin/bash
#
#


if [[ "${1}" == "bash" ]] || [[ "${1}" == "sh" ]] || [[ "${1}" == "zsh" ]] || [[ "${1}" == "ksh" ]]; then
	shift
fi

_DOMAIN=( "${@:1}" )

if [ -z ${_DOMAIN} ]; then
	_DOMAIN=("federation-edugain" "Default" "MESOLR")
fi

for dom in ${_DOMAIN[*]}
do
	echo ${dom}
	openstack user list --domain ${dom} --long -c Name -c Email
done
