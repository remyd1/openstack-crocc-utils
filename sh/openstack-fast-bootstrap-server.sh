#!/bin/bash

set -e

usage() {
	echo -e "Usage: \n$0 -i <instance name> -I <image name> -p <privnet network name> \
-P <pubnet network name> -[Kk] <keypair name> -f <flavor name> -s <secgroup name> \
-c <user-data file>

	-K: new keypair,
	-k: use existing keypair,
	-P: use pubnet to generate a floating IP (FIP) into this pubnet network,
	-s: security group name (multiple values delimiter is ',')
	-i: the name you want for your instance,
	-I: the image name to instance,
        -c: user-data file (cloud-init).

	"; 
	exit 1;
}

[ $# -eq 0 ] && usage
while getopts ":i:I:p:P:k:K:f:s:c:" arg; do
  case $arg in
    i)
      echo "instance: ${OPTARG}"
      INSTANCE=${OPTARG}
      ;;
    I)
      echo "Image: ${OPTARG}"
      IMAGE=${OPTARG}
      ;;
    p)
      echo "privnet: ${OPTARG}"
      PRIVNET=${OPTARG}
      ;;
    P)
      echo "Pubnet: ${OPTARG}"
      PUBNET=${OPTARG}
      ;;
    K)
      echo "New Keypair: ${OPTARG}"
      NEWKEYPAIR=${OPTARG}
      ;;
    k)
      echo "keypair: ${OPTARG}"
      KEYPAIR=${OPTARG}
      ;;
    f)
      echo "flavor: ${OPTARG}"
      FLAVOR=${OPTARG}
      ;;
    s)
      echo "Security group: ${OPTARG}"
      SECGROUP=${OPTARG}
      ;;
    c)
      echo "user-data file: ${OPTARG}"
      CLOUDINIT=${OPTARG}
      ;;
    h | *)
      usage
      exit 0
      ;;
  esac
done


# ensuite il faut sourcer un fichier .rc qui peut etre telecharge
# depuis l'interface Horizon
#source xxxxxx-openrc.sh


_OPENSTACK_SERVER_CREATION_BEGIN="openstack server create"

if [ -n "${INSTANCE}" ]; then
    _OPENSTACK_SERVER_CREATION_END=" ${INSTANCE}"
else
    usage
    echo "instance name is required"
fi


if [ -n "${NEWKEYPAIR}" ]; then
    openstack keypair create ${NEWKEYPAIR} > ${NEWKEYPAIR}.rsa
    openstack keypair show --public-key ${NEWKEYPAIR} > ${NEWKEYPAIR}.rsa.pub
    chmod 600 ${NEWKEYPAIR}.rsa
    KEYPAIR=${NEWKEYPAIR}
fi

if [ -n "${PUBNET}" ]; then
    openstack floating ip create ${PUBNET}
fi

#FIP=`openstack floating ip list |awk '{ if ($6 ~ "None") { print $2 } }' |head -1`
FIP=`openstack floating ip list -f value -c ID --status DOWN |head -1`


_OPENSTACK_OPTS=""
if [ -n "${SECGROUP}" ]; then
	if [[ "${SECGROUP}" =~ "," ]]; then SECGROUP=`echo ${SECGROUP} | sed -e 's/,/ --security-group /g'`; fi
	_OPENSTACK_OPTS=" ${_OPENSTACK_OPTS} --security-group ${SECGROUP}"
fi
if [ -n "${KEYPAIR}" ]; then
	_OPENSTACK_OPTS=" ${_OPENSTACK_OPTS} --key-name ${KEYPAIR}"
fi
if [ -n "${IMAGE}" ]; then
	_OPENSTACK_OPTS=" ${_OPENSTACK_OPTS} --image ${IMAGE}"
fi
if [ -n "${FLAVOR}" ]; then
	_OPENSTACK_OPTS=" ${_OPENSTACK_OPTS} --flavor ${FLAVOR}"
fi
if [ -n "${PRIVNET}" ]; then
	_OPENSTACK_OPTS=" ${_OPENSTACK_OPTS} --network ${PRIVNET}"
fi
if [ -n "${CLOUDINIT}" ]; then
	_OPENSTACK_OPTS=" ${_OPENSTACK_OPTS} --user-data ${CLOUDINIT}"
fi

_OPENSTACK_SERV_CREATE_CMD="${_OPENSTACK_SERVER_CREATION_BEGIN} ${_OPENSTACK_OPTS} ${_OPENSTACK_SERVER_CREATION_END}"

eval "${_OPENSTACK_SERV_CREATE_CMD}"
#openstack server create --flavor ${FLAVOR} --image ${IMAGE} --key-name ${KEYPAIR} --security-group ${SECGROUP} --user-data ${CLOUDINIT} --network ${PRIVNET} ${INSTANCE}


# adding public FIP to server
openstack server add floating ip ${INSTANCE} ${FIP}
# show logs
openstack console log show ${INSTANCE}
