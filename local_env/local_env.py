"""Local Env Class"""
# local_env/local_env.py

import os
from pathlib import Path
import dockerpty
import netifaces
import socket
import docker


class LocalEnvironment:
    """Class to facilitate creating and destroying the stack using ansible playbooks that ultimately
    run application/s on the host machine docker via docker
    """

    __docker_client = docker.from_env()
    __container: docker
    __gateways = netifaces.gateways()
    __image = "gitlab.library.upenn.edu/docker/hvas:master"
    __interface = __gateways["default"][netifaces.AF_INET][1]
    __pwd = os.getcwd()
    __vault_url = "https://vault.library.upenn.edu"

    def __init__(self, app_dir: str, deploy_environment: str, project_name: str,
                 vault_token: str = "", vault_endpoint: str = "", inventory: str = "local"):
        """
        Args:
            app_dir (str): The application source directory within the controller container
            vault_token (str): The HashiCorp vault token used to decrypt the Ansible vault files
            vault_endpoint (str): The HashiCorp vault endpoint that stores the Ansible vault
                                  password (must end in /)
            deploy_environment (str): Used for the Ansible vault-id when decrypting
        """

        self.container_name = f"{project_name}_{deploy_environment}_controller"
        self.deploy_environment = deploy_environment
        self.inventory = inventory
        self.image = self.__image
        self.environment = {
            "UID": os.getuid(),
            "GID": os.getgid(),
            "ANSIBLE_CONFIG": f"{app_dir}/ansible.dev.cfg",
            "HOST_HOSTNAME": socket.gethostname(),
            "HOST_INTERFACE": self.__interface,
            "HOST_ADDRESS": netifaces.ifaddresses(self.__interface)[netifaces.AF_INET][0]["addr"],
            "BASE_DIR": Path(self.__pwd).parent,
            "VAULT_ADDR": self.__vault_url
        }
        self.vault_endpoint = vault_endpoint
        self.vault_token = vault_token
        self.vault_url = self.__vault_url
        self.volumes = [
            "/var/run/docker.sock:/var/run/docker.sock",
            f"{Path(self.__pwd).parent}/ansible:{app_dir}"
        ]
        self.working_dir = app_dir

    def handle_stack(self, status: str = "create", remove_container: bool = True) -> None:
        """Spins up or connects to the controller container, installs the ansible roles, creates a
        vault password file, and runs the appropriate Ansible playbook

        Args:
            status (str, optional): Create or destroy the stack. Defaults to "create".
            remove_container (bool, optional): Whether or not to remove the controller container
                                               when done. Defaults to True.
        """

        playbook: str

        if status == "destroy":
            playbook = "rm_stack.yml"
        elif status == "create":
            playbook = "site.yml"

        try:
            if self.is_container_running():
                self.set_container()
            else:
                self.start_container()

            self.install_ansible_roles()

            if self.vault_endpoint and self.vault_token:
                self.create_ansible_vault_password_file()

            self.run_ansible_playbook(playbook)
        except Exception as exception:
            raise exception
        finally:
            self.remove_ansible_vault_password_file()

            if remove_container:
                self.remove_container()

    def is_container_running(self) -> bool:
        """Determines if the controller container is running

        Returns:
            bool: Is the container running
        """

        try:
            container: docker = self.__docker_client.containers.get(self.container_name)
        except docker.errors.NotFound:
            return False
        else:
            return container.attrs["State"]["Running"]

    def start_container(self) -> None:
        """Starts the controller container and keep it running by tailing /dev/null
        """

        try:
            command = "tail -f /dev/null"
            self.__container = self.__docker_client.containers.run(self.image, command, detach=True,
                                                                   environment=self.environment,
                                                                   volumes=self.volumes,
                                                                   working_dir=self.working_dir,
                                                                   name=self.container_name,
                                                                   stdin_open=True, tty=True)
        except Exception as exception:
            raise exception

    def remove_container(self) -> None:
        """Remove the controller container
        """

        self.__container.remove(force=True)

    def set_container(self) -> None:
        """Sets the container object to the given container
        """

        try:
            self.__container = self.__docker_client.containers.get(self.container_name)
        except Exception as exception:
            raise exception

    def run_command_in_container(self, command: str) -> None:
        """Runs any command within the container
        """

        try:
            result = self.__container.exec_run(command, stream=True)
            for line in result.output:
                print(line.decode())
        except Exception as exception:
            raise exception

    def install_ansible_roles(self) -> None:
        """Install the roles and/or collections found in requirements.yml
        """

        command = "ansible-galaxy install -g -f -r roles/requirements.yml"
        self.run_command_in_container(command)

    def run_ansible_playbook(self, playbook: str) -> None:
        """Runs a playbook within the container

        Args:
            playbook (str): The playbook to be run
        """
        if self.vault_endpoint and self.vault_token:
            command = f"ansible-playbook --vault-id={self.deploy_environment}@/tmp/.vault_pass \
                        -i inventories/{self.inventory} {playbook}"
        else:
            command = f"ansible-playbook -i inventories/{self.inventory} {playbook}"
        self.run_command_in_container(command)

    def remove_ansible_vault_password_file(self) -> None:
        """Remove the vault password
        """

        command = "rm -fr /tmp/.vault_pass"
        self.run_command_in_container(command)

    def create_ansible_vault_password_file(self) -> None:
        """Using the vault token grab the password used to decrypt the Ansible vault files
        and store it in a tmp file
        """

        self.remove_ansible_vault_password_file()

        command = f"/bin/bash -c 'VAULT_TOKEN={self.vault_token} vault kv get -field=password \
                    {self.vault_endpoint}{self.deploy_environment} > /tmp/.vault_pass'"
        self.run_command_in_container(command)

    def install_package(self, package: str) -> None:
        """Install package/s in the controller container

        Args:
            package (str): The package/s to install
        """

        command = f"/bin/bash -c 'apt-get update && apt-get install -y {package}'"
        self.run_command_in_container(command)

    def edit_ansible_vault_file(self, file: str) -> None:
        """Edit the Ansible Vault file

        Args:
            file (str): The Ansible vault file to be edited
        """

        try:
            command = f"ansible-vault edit --vault-id={self.deploy_environment}@/tmp/.vault_pass {file}"
            self.handle_stack("create", False)
            self.create_ansible_vault_password_file()
            self.install_package("vim")
            dockerpty.exec_command(self.__docker_client.api, self.__container.id, command)
        except Exception as exception:
            raise exception
        finally:
            self.remove_ansible_vault_password_file()
            self.remove_container()
