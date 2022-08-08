# 

## Local Development

In order to use the integrated development environment you will need to install [Docker](https://docs.docker.com/get-docker/) and [Python](https://wiki.python.org/moin/BeginnersGuide/Download).


#### Preparing

<u>Hosts File</u>

First, update your hosts file and add the following:

```
127.0.0.1 finding-aid-discovery-dev.library.upenn.edu
```

<u>Python Libraries</u>

Next, within the [local_env](local_env) directory, install the necessary python libraries by running the following:

```
python3 -m pip install -r requirements.txt
```

#### Creating and destroying the development environment

From the [local_env](local_env) directory run:

```
python3 main.py
```

After entring your HashiCorp Vault token, used to decrypt the Ansible Vault files, you will be presented with the following prompt:

```
> [1] Start local dev env
  [2] Remove local dev env
  [3] Edit vault File
  [4] Quit 
```

Pressing `1` will create the development environment which includes provisioning a single node docker swarm on your machine and running the ansible playbook to deploy the application. Keying `2` will remove the stack (i.e. associated services, containers, and labels). You are responsible for cleaning up any extraneous volumes (`docker volumes ls`) and images (`docker images ls`) associated with the stack. Pressing `3` will give you the option to select the file, decrypt using your token, and edit in VIM.
