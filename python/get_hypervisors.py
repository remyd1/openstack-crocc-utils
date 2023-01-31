#!/usr/bin/env python3

import sys
import logging
import openstack
import os_client_config

"""
From :
  https://docs.openstack.org/openstacksdk/latest/user/resources/compute/v2/hypervisor.html
  https://docs.openstack.org/openstacksdk/latest/user/connection.html

"""

FORMAT = '%(process)d-%(levelname)s-%(message)s'
logging.basicConfig(format=FORMAT)
LOG = logging.getLogger(__name__)


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


def get_hypervisor_usage(conn):
    """
    Returns some of the hypervisor informations
    """
    hypervisors = conn.list_hypervisors()
    for hyp in hypervisors:
        """
        # additionnal attrs are not available anymore:
        #https://github.com/openstack/openstacksdk/blob/master/openstack/compute/v2/hypervisor.py#L59
        """
        print("Name: ", hyp.name)
        print("ID: ", hyp.id)
        print("IP: ", hyp.host_ip)
        print("State: ", hyp.state)
        print("Status: ", hyp.status)
        print("Uptime: ", hyp.uptime)

if __name__ == '__main__':
    conn = connect()
    get_hypervisor_usage(conn)
