#!/bin/bash

if [[ "${1}" == "bash" ]] || [[ "${1}" == "sh" ]] || [[ "${1}" == "zsh" ]] || [[ "${1}" == "ksh" ]]; then
	shift
fi

_DOMAIN=( "${@:1}" )

if [ -z "${_DOMAIN}" ]; then
	_DOMAIN=("federation-edugain" "Default" "MESOLR")
fi

for dom in "${_DOMAIN[@]}"; do
	echo -e "#############\n${dom}\n#############\n#############\n"
    for project in $(openstack project list --domain "${dom}" -f value -c ID); do 
        echo -e "#####\nPROJET : ${project}\n#####"; openstack project show "${project}";
    done
done
