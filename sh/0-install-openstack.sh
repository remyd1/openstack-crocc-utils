#!/bin/bash

apt install -y python3-pip
python3 -m pip install --upgrade pip

python3 -m pip install python-openstackclient
python3 -m pip install python-neutronclient
python3 -m pip install python-designateclient
python3 -m pip install python-cloudkittyclient
python3 -m pip install python-manilaclient
python3 -m pip install python-cinderclient
python3 -m pip install python-ceilometerclient
python3 -m pip install os-client-config
python3 -m pip install osc-placement
