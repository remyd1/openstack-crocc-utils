#!/bin/bash

for project in `openstack project list -f value -c ID`; do echo -e "#####\nPROJET : ${project}\n#####"; openstack project show ${project}; done
