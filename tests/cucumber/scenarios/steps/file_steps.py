"""Author: Jakub Kudzia
Copyright (C) 2015 ACK CYFRONET AGH
This software is released under the MIT license cited in 'LICENSE.txt'

Module implements common steps for operation on all files.
"""

import pytest
from pytest_bdd import (given, when, then)
from pytest_bdd import parsers

from environment import docker, env
from common import *


@then(parsers.parse('{files} are in ls {path}'))
def ls_present(files, path, client_id, context):
    cmd = ["ls", context.mount_path + "/" + path]
    ls_files = docker.exec_(container=client_id, command=cmd, output=True).split()
    files = list_parser(files)
    for file in files:
        assert file in ls_files


@then(parsers.parse('{files} are not in ls {path}'))
def ls_absent(files, path, client_id, context):
    cmd = ["ls", context.mount_path + "/" + path]
    ls_files = docker.exec_(container=client_id, command=cmd, output=True).split()
    files = list_parser(files)
    for file in files:
        assert file not in ls_files
        

@when(parsers.parse('{user} renames {file1} to {file2}'))
def rename(user, file1, file2, client_id, context):

    ret = docker.exec_(container=client_id,
                       command=["mv", '/'.join([context.mount_path, file1]),
                                '/'.join([context.mount_path, file2])])
    save_op_code(context, ret)


@when(parsers.parse('{user} deletes files {files}'))
def delete_file(user, files, client_id,context):
    files = list_parser(files)
    for file in files:
        ret = docker.exec_(container=client_id,
                           command=["rm", '/'.join([context.mount_path, file])])
        save_op_code(context, ret)


@then(parsers.parse('{file} file type is {fileType}'))
def check_type(file, fileType, client_id, context):
    currFileType = docker.exec_(container=client_id,
                        command=["stat", '/'.join([context.mount_path, file]), "--format=%F"],
                        output=True)
    assert fileType == currFileType


@then(parsers.parse('{file} mode is {mode}'))
def check_mode(file, mode, client_id, context):
    curr_mode = docker.exec_(container=client_id,
                     command=["stat", "--format=%a", '/'.join([context.mount_path, file])],
                     output=True)
    assert mode == curr_mode


@when(parsers.parse('{user} changes {file} mode to {mode}'))
def change_mode(user, file, mode, client_id, context):
    docker.exec_(container=client_id,
                 command=["chmod", mode, '/'.join([context.mount_path, file])])


@then("clean succeeds")
def clean(client_id, context):

    spaces = docker.exec_(container=client_id, command=['ls', context.mount_path + '/spaces'],
                          output=True)
    spaces = spaces.split("\n")

    # clean spaces
    for space in spaces:
        docker.exec_(container=client_id,
                     command="rm -rf " + '/'.join([context.mount_path, 'spaces', str(space), '*']))

    pid = docker.exec_(container=client_id,
                       command="ps aux | grep './oneclient --authentication token' | " +
                       "grep -v 'grep' | awk '{print $2}'", output=True)
    # kill oneclient process
    docker.exec_(container=client_id, command="kill -KILL " + str(pid), output=True)
    # unmount onedata
    docker.exec_(container=client_id, command="umount " + context.mount_path)
    # remove onedata dir
    ret = docker.exec_(container=client_id, command="rm -rf " + context.mount_path)
    save_op_code(context, ret)
    success(client_id, context)