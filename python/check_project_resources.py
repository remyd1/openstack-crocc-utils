#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__author__      = "Rémy Dernat"


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
    print("python3 check_project_resources.py")

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

def get_resources(conn):
    """
    Search and returns all the OpenStack objects
    belonging to a specific project ID.
    """
    valid_resources = [ 'networks', 'routers', 'subnets', 'floating_ips', \
        'ports', 'servers', 'security_groups' ]
    for res in valid_resources:
        res_arr = getattr(conn, 'list_' + res)()
        if res == 'servers' and res_arr:
            for serv in res_arr:
                #print(repr(serv))
                print("A server exists within your project %s" % conn.current_project_id)
                print(".... server name: %s, with ID: %s"  % (serv.name, serv.id))
                try:
                    volume_list = conn.get_volumes(serv.id)
                except Exception as VolIssue:
                    LOG.critical(VolIssue)
                #if volume_list:
                #    print(repr(volume_list))
                    #for vol in volume_list:
                        #print("A volume is attached to the server %s" % serv.name)
                        #print(".... volume name: %s, with ID: %s" % (vol.name, vol.id))
        else:
            for curr_res in res_arr:
                if curr_res.project_id == conn.current_project_id:
                    if res == "floating_ips":
                        name = curr_res.floating_ip_address
                    else:
                        name = curr_res.name
                    print("A %s exists within your project %s" % (res, conn.current_project_id))
                    print(".... %s resource: %s, with ID: %s"  % (res, name, curr_res.id))

if __name__ == '__main__':
    conn = connect()
    try:
        get_resources(conn)
    except Exception as GeneralIssue:
        LOG.critical(GeneralIssue)
        usage()
