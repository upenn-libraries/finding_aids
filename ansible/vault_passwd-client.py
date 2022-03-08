#!/usr/bin/python3

# https://docs.ansible.com/ansible/latest/user_guide/vault.html#storing-passwords-in-third-party-tools-with-vault-password-client-scripts
# Storing passwords in third-party tools with vault password client scripts
#  - Create a file with a name ending in -client.py
#  - Make the file executable
#  - Within the script itself:
#     - Print the passwords to standard output
#     - Accept a --vault-id option
#     - If the script prompts for data (for example, a database password), send the prompts to standard error

import argparse
import getpass
import hvac
import sys

class HashicorpVault:
    VAULT_URL = "https://vault.library.upenn.edu"

    def __init__(self, username, password, vault_id):
        self._client = hvac.Client(url=HashicorpVault.VAULT_URL)
        self.password = password
        self.username = username
        self.vault_id = vault_id

    # get the ansible vault password
    def get_vault_password(self):
        try:
            self.login()

            results = self._client.secrets.kv.read_secret(
                mount_point = "finding-aid-discovery",
                path = "ansible/vault/" + self.vault_id
            )

            return results["data"]["data"]["password"]
        except Exception as e:
            raise e

    # login to hashicorp vault via ldap
    def login(self):
        try:
            self._client.auth.ldap.login(
                username = self.username,
                password = self.password,
                mount_point = "ldap"
            )
        except Exception as e:
            raise SystemExit(e)

# get the value of --vault-id. This parameter is passed down via the ansible-playbook or
# ansible-vault command when supplied
def get_vault_id():
    parser = argparse.ArgumentParser()
    parser.add_argument("--vault-id", action="store", dest="vault_id", default=None)
    args = parser.parse_args()
    vault_id = args.vault_id

    if vault_id is None:
        raise IndexError("--vault-id must be included as an arg and include a label. e.g. --vault-id production@vault_passwd-client.py")

    return vault_id

if __name__ == '__main__':
    try:
        vault_id = get_vault_id()

        # we use getpass for username because for ansible to work properly prompts
        # must be sent to stderr and the input method sends to stdout which appends
        # the output to the password. the downside is that the user is not able to 
        # see their username as they enter it
        username = getpass.getpass(prompt="Username: ", stream=None)
        passwd = getpass.getpass(prompt="Password: ", stream=None)

        # instantiate the HashicorpVault object
        hv = HashicorpVault(username, passwd, vault_id)

        # echo the ansible vault password
        print(hv.get_vault_password())
    except Exception as e:
        raise e
