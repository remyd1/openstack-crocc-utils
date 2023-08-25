#!/bin/bash

for secgroup in `openstack security group list -f value -c ID`; do echo "#####\nRULES FOR SECGROUP : ${secgroup}\n#####"; openstack security group rule list ${secgroup}; done
