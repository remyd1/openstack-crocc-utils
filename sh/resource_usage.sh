#!/bin/bash

vals=$(openstack resource provider list  -c uuid -c name -f value)

for val in $(echo ${vals})
do
	if [[ "${val}" =~ "nova" ]]; then
		# compute node hostname
		echo ${val}
	        echo "########################################################"
	else
		openstack resource provider usage show ${val}
	fi
done
