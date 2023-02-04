#!/bin/bash
#
#


_OPENSTACK=`command -v openstack`
_NEUTRON=`command -v neutron`


usage="$0 <project_id>"
if [ -z "${1}" ]; then
	echo $usage
	exit 1
else
	if [[ "${1}" == "--help" ]] || [[ "${1}" == "-h" ]]; then
		echo $usage
		exit 1
	fi
	PROJECT_ID=${1}
fi

if [ -z "${_OPENSTACK}" ]; then
	echo "openstack command not found... Exiting"
	exit 1
fi

if [ -z "${_NEUTRON}" ]; then
	echo "neutron command not found... Exiting"
	exit 1
fi

${_OPENSTACK} project purge --project ${PROJECT_ID}
${_NEUTRON} purge ${PROJECT_ID}
