#!/usr/bin/env python3
 # -*- coding: utf-8 -*-

"""
check_orphan_resources.py: This script will list the resources
that are allocated to non-existing Project IDs.

Updated to python3 and OpenStackSDK.

From:
  https://github.com/vinothkumarselvaraj/openstack-orphaned-resource
  https://github.com/openstack/openstacksdk/tree/master/examples
  https://docs.openstack.org/openstacksdk/latest/user/connection.html

TODO:
  argparse, connect (https://github.com/openstack/openstacksdk/blob/master/examples/connect.py)

"""

__author__      = "Vinoth Kumar Selvaraj"
__update__      = "Rémy Dernat"


import sys
import logging
import openstack
import os_client_config

FORMAT = '%(process)d-%(levelname)s-%(message)s'
logging.basicConfig(format=FORMAT)
LOG = logging.getLogger(__name__)

def usage():
    """
    Usage basic function
    Returns nothing but text
    """
    print("check_orphan-resources.py <object> where object is one or more of")
    print("'networks', 'routers', 'subnets', 'floatingips', 'ports', \
'servers', 'secgroups' or 'all'")

### Initialize and turn on debug logging
#openstack.enable_logging(debug=True)

def connect():
    """
    Connection method
    May be needed to be replaced by pure Openstacksdk method soon
    returns Connector
    """
    try:
        config = os_client_config.get_config()
        conn = openstack.connection.Connection(config=config)
        conn.authorize()
        return conn
    except Exception as curr_error:
        LOG.exception('Connection error : %s', curr_error, exc_info=1)

def get_projects_ids(conn):
    """
    Returns all the projects IDs
    """
    return [project.id for project in conn.identity.projects()]

def get_orphan_objs(conn, projectids, obj):
    """
    Search and returns all the orphan OpenStack objects
    """
    projectids.append("")
    if obj == "servers":
        object_list = getattr(conn, 'list_' + obj)(all_projects=True)
    else:
        object_list = getattr(conn, 'list_' + obj)()
    orphans = []
    for osk_obj in object_list:
        if osk_obj['tenant_id'] not in projectids:
            orphans.append(osk_obj['id'])
    return orphans

def get_orphaned_subnets(conn, projectids):
    """
    Search and returns all the orphan subnets
    """
    projectids.append("")
    subnets_orphans = []
    for subnet in conn.list_subnets():
        if subnet.tenant_id not in projectids:
            subnets_orphans.append(subnet.id)
    return subnets_orphans

if __name__ == '__main__':
    conn = connect()
    projectids = get_projects_ids(conn)
    valid_options = [ 'networks', 'routers', 'subnets', 'floatingips', \
        'ports', 'servers', 'secgroups' ]
    if len(sys.argv) > 1:
        if sys.argv[1] == 'all':
            ostack_objects = valid_options
        else:
            ostack_objects = sys.argv[1:]
        for ostack_object in ostack_objects:
            if ostack_object not in valid_options:
                LOG.error("%s object is not an OpenStack valid object", \
                    ostack_object, exc_info=1)
                usage()
                break
            if ostack_object == 'secgroups':
                ostack_object = 'security_groups'
            if ostack_object == 'floatingips':
                ostack_object = 'floating_ips'
            orphans = get_orphan_objs(conn, projectids, ostack_object)
            print(len(orphans), 'orphan(s) found of type', ostack_object)
            print('\n'.join(map(str, orphans)))
    else:
        usage()
