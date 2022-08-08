"""Local Env entry point script"""
# local_env/main.py

import getpass
from menu import render_menu
from local_env import LocalEnvironment


def main():
    """Entrypoint
    """
    vault_token = getpass.getpass(prompt="Vault Token: ", stream=None)
    local_env = LocalEnvironment(app_dir="/app", deploy_environment="local",
                                 project_name="fad", vault_token=vault_token,
                                 vault_endpoint="ansible/vault/finding-aid-discovery/")

    render_menu(local_env)


if __name__ == "__main__":
    main()
