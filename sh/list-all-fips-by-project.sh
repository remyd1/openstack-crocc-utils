#!/bin/bash

if [[ "${1}" == "bash" ]] || [[ "${1}" == "sh" ]] || [[ "${1}" == "zsh" ]] || [[ "${1}" == "ksh" ]]; then
	shift
fi


openstack floating ip list -c "Floating IP Address" -c Project

