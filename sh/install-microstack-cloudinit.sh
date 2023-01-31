#!/bin/bash

# ubuntu name resolution systemd-resolved
mkdir -p /etc/systemd/resolved.conf.d/
cat << EOF > /etc/systemd/resolved.conf.d/dns_servers.conf
[Resolve]
DNS=193.51.152.152 193.51.152.153
EOF
systemctl restart systemd-resolved.service

# installing snap and microstack
apt update
apt install -yqq snapd
snap install microstack --beta
