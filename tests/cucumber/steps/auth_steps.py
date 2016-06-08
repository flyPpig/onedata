"""Module implements pytest-bdd steps for authorization and mounting oneclient.
"""
__author__ = "Jakub Kudzia"
__copyright__ = "Copyright (C) 2015 ACK CYFRONET AGH"
__license__ = "This software is released under the MIT license cited in " \
              "LICENSE.txt"

from pytest_bdd import given

import multi_auth_steps
from tests.utils.client_utils import mount_users
from tests.utils.cucumber_utils import *


@given(parsers.parse('{user} starts oneclient in {mount_path} using {token}'))
def default_mount(user, mount_path, token, request, onedata_environment, context,
                  client_ids, env_description_file):
    mount_users(request, onedata_environment, context, client_ids, env_description_file,
                users=[user], client_instances=["client1"],
                mount_paths=[mount_path], client_hosts=['client-host1'],
                tokens=[token])


@then(parsers.parse('{spaces} are mounted for {user}'))
def check_spaces(spaces, user, context):
    multi_auth_steps.check_spaces(spaces, user, make_arg_list("client1"),
                                  context)
