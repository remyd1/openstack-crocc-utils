#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__author__      = "Rémy Dernat"

"""
https://github.com/openstack/python-cloudkittyclient/blob/master/doc/source/usage.rst

Useful cloudkitty examples with CLI :
    cloudkitty dataframes get -b 2023-03-01T00:00:00 -f df-to-csv > 20230301_20230317_cloud_kitty_df.csv
    openstack rating summary get -b 2022-03-01T00:00:00 -e 2023-04-01T00:00:00 -a
"""

import sys
import os
import logging
import openstack

from keystoneauth1 import session
from keystoneauth1.identity import v3
import os_client_config

from cloudkittyclient import client as ck_client

FORMAT = '%(process)d-%(levelname)s-%(message)s'
logging.basicConfig(format=FORMAT)
LOG = logging.getLogger(__name__)

def usage():
    """
    Usage basic function
    Returns nothing but text
    """
    print("source admin-openrc.sh && python3 cloudkitty_report.py")

### Initialize and turn on debug logging
#openstack.enable_logging(debug=True)

def connect():
    """
    Connection method
    returns auth object
    """
    try:
        auth = v3.Password(
            auth_url=os.environ.get('OS_AUTH_URL'),
            project_domain_name=os.environ.get('OS_PROJECT_DOMAIN_NAME'),
            user_domain_name=os.environ.get('OS_USER_DOMAIN_NAME'),
            username=os.environ.get('OS_USERNAME'),
            project_name=os.environ.get('OS_PROJECT_NAME'),
            password=os.environ.get('OS_PASSWORD'))
        return auth
    except Exception as auth_error:
        LOG.exception('Connection error : %s', auth_error, exc_info=1)


if __name__ == '__main__':
    auth = connect()
    try:
        ck_session = session.Session(auth=auth)
        c = ck_client.Client('1', session=ck_session)
        c.report.get_summary()
    except Exception as GeneralIssue:
        LOG.critical(GeneralIssue)
        usage()
    
