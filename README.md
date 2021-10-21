## Finding Aid Discovery
---

- [Development](#development)
  - [Starting](#starting)
  - [Stopping](#stopping)
  - [Destroying](#destroying)
  - [SSH](#ssh)
  - [Traefik](#traefik)

## Development

> Caveat: the vagrant development environment has only been tested in Linux.

In order to use the integrated development environment you will need to install [VirtualBox](https://www.virtualbox.org/wiki/Linux_Downloads) and [Vagrant](https://www.vagrantup.com/docs/installation), and the following Vagrant plugins: vagrant-vbguest, and vagrant-hostsupdater:

```
vagrant plugin install vagrant-vbguest vagrant-hostsupdater
```

#### Starting

From the `vagrant` directory run (the ansible vault password for the vagrant inventory is `password`):

```
vagrant up --provision
```

This will run the [vagrant/Vagrantfile](vagrant/Vagrantfile) which will bring up an Ubuntu VM and run the Ansible script which will provision a single node Docker Swarm behind nginx with a self-signed certificate to mimic a load balancer. Your hosts file will be modified; the domain `finding-aid-discovery-dev.library.upenn.edu` will be added and mapped to the Ubuntu VM. Once the Ansible script has completed and the Docker Swarm is deployed you can access the application by navigating to [https://finding-aid-discovery-dev.library.upenn.edu](https://finding-aid-discovery-dev.library.upenn.edu).

#### Stopping

To stop the development environment, from the `vagrant` directory run:

```
vagrant halt
```

#### Destroying

To destroy the development environment, from the `vagrant` directory run:

```
vagrant destroy -f
```

#### SSH

You may ssh into the Vagrant VM by running:

```
ssh -i ~/.vagrant.d/insecure_private_key vagrant@finding-aid-discovery-manager
```

#### Traefik

When running the development environment you can access the traefik web ui by navigating to: [https://finding-aid-discovery-dev.library.upenn.edu:8080/#](https://finding-aid-discovery-dev.library.upenn.edu:8080/#). The username and password are located in [ansible/inventories/vagrant/group_vars/docker_swarm_manager/traefik.yml](ansible/inventories/vagrant/group_vars/docker_swarm_manager/traefik.yml)
