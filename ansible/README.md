## Finding Aid Discovery - Ansible
---

- [Vault Files](#vault-files)

## Vault Files

The passwords for the vault files are stored in HashiCorp Vault and are made accessible by using the appropriate `vault-id` along with the convenience script: [vault_passwd-client.py](vault_passwd-client.py). See the [Ansible documentation](https://docs.ansible.com/ansible/latest/user_guide/vault.html#storing-passwords-in-third-party-tools-with-vault-password-client-scripts) for more information.

First, the client script must be executable (e.g. `chmod +x vault_passwd-client.py`) and the [hvac package](https://pypi.org/project/hvac/) must be installed (`pip install hvac`). The previous requirements have been addressed within the Vagrant development environment; you can skip those steps and freely interact with the vault files when working in the virtual machine.

Next, ensure you are a member of the group or have the appropriate permissions to access the HashiCorp Vault endpoint. Then, to edit the `finding_aid_discovery_vault.yml` file in the vagrant inventory with the `vagrant` vault-id for example, run the following command:

```
ansible-vault edit --vault-id vagrant@vault_passwd-client.py inventories/vagrant/group_vars/docker_swarm_manager/finding_aid_discovery_vault.yml
```

You will be prompted for your credentials. After you are authorized you will be able to modify the contents of the file. 


Below is a breakdown of the process when attempting to decrypt using the vault-id and script:

```mermaid
sequenceDiagram
    autonumber
    participant cli
    participant Ansible Playbook
    participant Ansible Vault
    participant Ansible Vault Script
    participant Hashicorp Vault
    cli->>Ansible Playbook: User runs playbook command
    Ansible Playbook->>Ansible Vault: Encounters encrypted vars
    Ansible Vault->>Ansible Vault Script: Passes "vault_id" to custom script
    Ansible Vault Script->>cli: Script prompts for users ldap username and password
    cli-->>Ansible Vault Script: If user is authenticated and has permissions to access the specified route, then the process proceeds else process fails
    Ansible Vault Script->>Hashicorp Vault: Request is made to API for vault password using vault_id
    Hashicorp Vault->>Ansible Vault Script: If response is successful, the value is returned
    Ansible Vault Script->>Ansible Vault: The vault password is echoed via stdout
    Ansible Vault->>Ansible Playbook: Processing returns
```
