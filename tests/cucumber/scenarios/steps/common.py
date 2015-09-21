"""Author: Piotr Ociepka
Copyright (C) 2015 ACK CYFRONET AGH
This software is released under the MIT license cited in 'LICENSE.txt'

Module implements some common basic functions and functionality.
"""

import pytest
from pytest_bdd import then

from environment import docker

####################### CLASSES #######################

class Context:
    def __init__(self):
        pass

###################### FIXTURES  ######################

@pytest.fixture(scope="module")
def context():
    return Context()


@pytest.fixture(scope="module")
def client_id(environment):
    client = environment['client_nodes'][0]
    return docker.inspect(client)['Id']


######################## STEPS ########################

@then("last operation succeeds")
def success(client_id):
    assert docker.exec_(container=client_id, command="echo $?", output=True) == '0'

@then("last operation fails")
def failure(client_id):
    return docker.exec_(container=client_id, command="echo $?", output=True) != '0'

###################### FUNCTIONS ######################

def list_parser(list):
    return [el.strip() for el in list.strip("[]").split(',')]

