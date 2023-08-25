# crocc-utils

_Author: Rémy Dernat_

Collection of basic useful scripts to manage an OpenStack cloud.

Description:
  - `python/get_hypervisors.py`: get hypervisors basic informations,
  - `python/check_orphan_resources.py`: check orphan resources,
  - `python/check_project_resources.py`: check resources belonging to a project/tenant,
  - `sh/0-install-openstack.sh`: install openstack client libraries,
  - `sh/1-install-kolla.sh`: install kolla-ansible,
  - `sh/cpu_usage.sh`: check cpu usage on hypervisor using libvirt,
  - `sh/cur_openstack_usage.sh`: check hypervisor and FIP usage on OpenStack cluster,
  - `sh/install-microstack-cloudinit.sh`: cloud-init/userdata file to install microstack,
  - `sh/openstack-fast-bootstrap-server.sh`: create an instance (VM server),
  - `sh/remove_proj_all.sh`: remove a project and related network resources based on project/tenant ID,
  - `sh/remove-orphan-networks-with-resources.sh`: remove orphan networks with associated resources (using `python/check_orphan_resources`),
  - `sh/list-all-secgroups.sh`: list all security groups (...),
  - `sh/list-all-projects.sh`: show all projects (...),
  - `sh/list-crocc-users.sh`: list all users belonging to domains.
