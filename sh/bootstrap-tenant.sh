# This script is used to bootstrap a tenant for a new project 

# CHANGE THE VARIABLES BELOW EACH TIME YOU USE THIS SCRIPT
TENANT_PROJECT=""
TENANT_MAIL=""


TENANT_QUOTA_VCPUS=16
# IN GB
TENANT_QUOTA_RAM=65536
TENANT_QUOTA_INSTANCES=10
TENANT_QUOTA_GIGABYTES=500
TENANT_QUOTA_FIP=10

ADMIN_MAIL="arsene.fougerouse@etu.umontpellier.fr"
PUBLIC_NETWORK="public2"
DOMAIN="federation-edugain"

if [ -z "$OS_CLOUD" ]; then
  echo "❌: You must source the OpenStack RC file"
  exit 1
fi

# Prompt to enter the TENANT-PROJECT variable:
printf "Enter the project name > "
read -r TENANT_PROJECT
if [ -z "$TENANT_PROJECT" ]; then
  echo "❌: You must set the variable TENANT_PROJECT"
  exit 1
fi

# Prompt to enter the TENANT_MAIL variable:
printf "Enter the email of the tenant > "
read -r TENANT_MAIL
if [ -z "$TENANT_MAIL" ]; then
  echo "❌: You must set the variable TENANT_MAIL"
  exit 1
fi

VAR_CREATION="c"
# Prompt to ask if it is a creation or a modification
printf "Is it a creation or a user adding to a project ? (c/a) 'default=c' > "
read -r VAR_CREATION

if [ -z "$VAR_CREATION" ]; then
  VAR_CREATION="c"
fi

if [ "$VAR_CREATION" != "c" ] && [ "$VAR_CREATION" != "a" ]; then
  echo "❌: The answer must be c or a"
  exit 1
fi

if [ "$VAR_CREATION" == "a" ]; then
  # prompt to enter the domain name, must fail if domain is not federation-edugain or default
  printf "Enter the domain name (default to ${DOMAIN})> "
  read -r VAR_DOMAIN
  if [ ! -z "$VAR_DOMAIN" ]; then
    DOMAIN=$VAR_DOMAIN
    if [ "$VAR_DOMAIN" != "federation-edugain" ] && [ "$VAR_DOMAIN" != "default" ]; then
      echo "❌: The domain name must be set to federation-edugain or default"
    exit 1
    fi
  fi
fi

TENANT_USER_ID=$(openstack user list --domain $DOMAIN --long -f value -c ID -c Name -c Email | grep $TENANT_MAIL | cut -d\  -f1)

if [ -z $TENANT_USER_ID ]; then
  echo "❌ User not found with $TENANT_MAIL"
  exit 1
fi

if [ "$VAR_CREATION" == "a" ]; then
  openstack role add --user $TENANT_USER_ID --project $TENANT_PROJECT member
  openstack role add --user $TENANT_USER_ID --project $TENANT_PROJECT reader
  openstack role add --user $TENANT_USER_ID --project $TENANT_PROJECT heat_stack_owner
  openstack role add --user $TENANT_USER_ID --project $TENANT_PROJECT load-balancer_member
  echo "✅ User $TENANT_MAIL added to the project $TENANT_PROJECT"
  exit 0
fi


ADMIN_USER_ID=$(openstack user list --domain federation-edugain --long -f value -c ID -c Name -c Email | grep $ADMIN_MAIL | cut -d\  -f1)



# Prompt to enter the nuber of vCPUS (default to ${TENANT_QUOTA_VCPUS})
printf "Enter the number of vCPUS (default to ${TENANT_QUOTA_VCPUS})> "
read -r TENANT_VCPUS
if [ ! -z "$TENANT_VCPUS" ]; then
  TENANT_QUOTA_VCPUS=$TENANT_VCPUS
fi

# Prompt to enter the RAM (default to ${TENANT_QUOTA_RAM})
printf "Enter the RAM in MB (default to ${TENANT_QUOTA_RAM})> "
read -r TENANT_RAM
if [ ! -z "$TENANT_RAM" ]; then
  TENANT_QUOTA_RAM=$TENANT_RAM
fi

# Prompt to enter the GIGABYTES (default to ${TENANT_QUOTA_GIGABYTES})
printf "Enter the number of Gigabytes for the storage (default to ${TENANT_QUOTA_GIGABYTES})> "
read -r TENANT_GIGABYTES
if [ ! -z "$TENANT_GIGABYTES" ]; then
  TENANT_QUOTA_GIGABYTES=$TENANT_GIGABYTES
fi

# Prompt to enter the TENANT_QUOTA_VCPUS variable:
printf "Enter the number of instances (default to ${TENANT_QUOTA_INSTANCES})> "
read -r TENANT_INSTANCES
# Set the default value if the user does not enter a value
if [ ! -z "$TENANT_INSTANCES" ]; then
  TENANT_QUOTA_INSTANCES=$TENANT_INSTANCES
fi

# prompt to enter the TENANT_QUOTA_FIP variable:
printf "Enter the number of floating IPs (default to ${TENANT_QUOTA_FIP})> "
read -r TENANT_FIP
if [ ! -z "$TENANT_FIP" ]; then
  TENANT_QUOTA_FIP=$TENANT_FIP
fi

# prompt to enter the network name
# Must be set to public for TOULOUSE or public2 for MONTPELLIER

printf "Enter the network name (default to ${PUBLIC_NETWORK})> "
read -r VAR_PUBLIC_NETWORK
# Check if the variable is equal to public, public1 or public2
if [ ! -z "$VAR_PUBLIC_NETWORK" ]; then
  PUBLIC_NETWORK=$VAR_PUBLIC_NETWORK
  if [ "$VAR_PUBLIC_NETWORK" != "public" ] && [ "$VAR_PUBLIC_NETWORK" != "public1" ] && [ "$VAR_PUBLIC_NETWORK" != "public2" ]; then
    echo "❌: The network name must be set to public, public1 or public2"
  exit 1
  fi
fi


# First, check if the project already exists
openstack project show $TENANT_PROJECT
if [ $? -eq 0 ]; then
  echo "❌ Project $TENANT_PROJECT already exists"
  exit 1
fi

# Prompt the creation with the quotas
echo "🔧 Creating project with following information:"
echo "🏗️ Project: $TENANT_PROJECT"
echo "📧 Email: $TENANT_MAIL"
echo "🖥️ Instances: $TENANT_QUOTA_INSTANCES"
echo "🏎️ VCPUS: $TENANT_QUOTA_VCPUS"
echo "🛢️ RAM: $TENANT_QUOTA_RAM"
echo "💽 Gigabytes: $TENANT_QUOTA_GIGABYTES"
echo "📌 Floating IPs: $TENANT_QUOTA_FIP"
echo "🔗 Network: $PUBLIC_NETWORK"
printf "Are you sure you want to continue ? (y/n) > "

read -r response
if [ "$response" != "y" ]; then
  echo "❌: Aborted"
  exit 1
fi

openstack project create $TENANT_PROJECT
echo "✅: Project $TENANT_PROJECT created"

openstack role add --user $TENANT_USER_ID --project $TENANT_PROJECT member
openstack role add --user $TENANT_USER_ID --project $TENANT_PROJECT heat_stack_owner
openstack role add --user $TENANT_USER_ID --project $TENANT_PROJECT load-balancer_member

# Temporary add the admin to the project
openstack role add --user $ADMIN_USER_ID --project $TENANT_PROJECT member
openstack role add --user $ADMIN_USER_ID --project $TENANT_PROJECT heat_stack_owner
openstack role add --user $ADMIN_USER_ID --project $TENANT_PROJECT load-balancer_member

echo "✅: Role added $TENANT_PROJECT !"

# création du réseau privé ('reseauprive' dans notre exemple)
UUIDNETWORK=$(openstack network create --project $TENANT_PROJECT private-subnet-$TENANT_PROJECT -f json | jq -r '.id')
# Création d'un subnet avec l' UUIDNETWORK obtenu
UUIDSUBNET=$(openstack subnet create --project $TENANT_PROJECT --subnet-range 172.22.1.0/24 --gateway 172.22.1.1 --dns-nameserver 1.1.1.1 --network $UUIDNETWORK private-subnet-$TENANT_PROJECT -f json | jq -r '.id')
# Crétion d'un routeur ('routeur" dans notre exemple)
UUIDROUTER=$(openstack router create --project $TENANT_PROJECT router-$TENANT_PROJECT -f json | jq -r '.id')
# Attachement du subnet au routeur
openstack router add subnet $UUIDROUTER $UUIDSUBNET
# Attachement à une external gateway : sur toulouse -> vpn-external (si passage par le vpn free ipa) ou public (si doit être accessible depuis internet) 
openstack router set --external-gateway $PUBLIC_NETWORK $UUIDROUTER

echo "✅: Networks and routers created !"

# Create Security groups
UUIDWEB=$(openstack security group create --project $TENANT_PROJECT web -f json | jq -r '.id')
UUIDICMP=$(openstack security group create --project $TENANT_PROJECT icmp -f json | jq -r '.id')
UUIDSSH=$(openstack security group create --project $TENANT_PROJECT ssh -f json | jq -r '.id')

# prendre les UUID de chacun pour l'ajout des règles
openstack security group rule create $UUIDICMP --protocol icmp
openstack security group rule create $UUIDSSH --protocol tcp --dst-port 22
openstack security group rule create $UUIDWEB --protocol tcp --dst-port 80
openstack security group rule create $UUIDWEB --protocol tcp --dst-port 443

echo "✅: Security rules and groups created !"

# Create Quota
openstack quota set --force --instances $TENANT_QUOTA_INSTANCES $TENANT_PROJECT
openstack quota set --force --cores $TENANT_QUOTA_VCPUS $TENANT_PROJECT
openstack quota set --force --ram $TENANT_QUOTA_RAM $TENANT_PROJECT
openstack quota set --force --gigabytes $TENANT_QUOTA_GIGABYTES $TENANT_PROJECT
openstack quota set --force --floating-ips $TENANT_QUOTA_FIP $TENANT_PROJECT

openstack quota show $TENANT_PROJECT

echo "✅: Script finished !"
echo "---------------------"

firefox -new-tab "https://federation.umontpellier.fr:5000/v3/auth/OS-FEDERATION/websso?origin=https://federation.umontpellier.fr/dashboard/auth/websso/"
echo "Don't forget to remove the admin from the project :"
echo "openstack role remove --user $ADMIN_USER_ID --project $TENANT_PROJECT member"
echo "openstack role remove --user $ADMIN_USER_ID --project $TENANT_PROJECT heat_stack_owner"
echo "openstack role remove --user $ADMIN_USER_ID --project $TENANT_PROJECT load-balancer_member"

echo "---------------------"
echo "👇: Add the information into the wiki"
firefox -new-tab "https://nextcloud.inrae.fr/apps/files/?dir=/crocc/Users/Liste-projets&fileid=120736818"

echo "---------------------"
echo "Adding user in the project"

GITLAB_API_URL="https://forgemia.inra.fr/api/v4"
GITLAB_PROJECT_ID="6767" # Project ID for the support
GITLAB_ACCESS_LEVEL="20" # Reporter access level
# Make an API call to Gitlab to add the user to the project

# Todo Parse user and name
# curl --request POST --header "PRIVATE: $GITLAB_PRIVATE_TOKEN" --data "user_id=$TENANT_USER_ID&access_level=$GITLAB_ACCESS_LEVEL&invite_source=$ADMIN_MAIL" "$GITLAB_API_URL/projects/$GITLAB_PROJECT_ID/members"

# # TODO Add this
# echo "--------------------"
# echo "Add user on Mattermost"
