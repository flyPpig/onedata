from tests.test_common import *
from tests import test_utils
import socket
import time
import os
import subprocess
import script_up_test
import ast

from environment import docker, env


class TestEnvUp:
    @classmethod
    # Run the evn_up.py script, capture and parse the output
    def setup_class(cls):
        logdir = get_logdir_name(acceptance_logdir, get_test_name(__file__))
        result = subprocess.check_output([
            os.path.join(docker_dir, "env_up.py"),
            test_utils.test_file('env.json'),
            '-l', logdir
        ])
        stripped_result = script_up_test.strip_output_logs(result)
        cls.result = ast.literal_eval(stripped_result)

    @classmethod
    # Clean up removing all dockers created in the test
    def teardown_class(cls):
        docker.remove(cls.result['docker_ids'], force=True, volumes=True)

    # Test if the env_up.py script works as expected.
    def test_env_up(self):
        env = self.result
        # Check if number of started dockers is correct
        # The number should be:
        # 1 dns node

        # 4 op_worker nodes
        # 2 cluster_manager nodes for op_workers
        # 2 DB nodes for op_workers

        # 1 GR nodes
        # 1 DB for GR nodes

        # 2 appmock nodes

        # 2 client nodes
        # ------------
        # 15 nodes
        assert 15 == len(env['docker_ids'])

        script_up_test.check_globalregistry_up(env, 1)
        script_up_test.check_cluster_manager_up(env, 2)
        script_up_test.check_provider_worker_up(env, 4)
        script_up_test.check_appmock_up(env, 2)
        script_up_test.check_client_up(env, 2)
