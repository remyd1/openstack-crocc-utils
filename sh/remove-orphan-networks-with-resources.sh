#!/bin/bash
#
#

for net in `../python/python check_orphan_resources.py networks |tail -n +2`
do 
	proj=$(openstack network show ${net} -f yaml -c project_id |awk '{print $2}')
	neutron purge ${proj}
done
