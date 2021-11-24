## Finding Aid Discovery
---

- [Development](#development)
  - [Starting](#starting)
  - [Stopping](#stopping)
  - [Destroying](#destroying)
  - [SSH](#ssh)
  - [Traefik](#traefik)
  - [Solr Admin](#solr-admin)

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
vagrant ssh
```

#### Traefik

When running the development environment you can access the traefik web ui by navigating to: [https://finding-aid-discovery-dev.library.upenn.edu:8080/#](https://finding-aid-discovery-dev.library.upenn.edu:8080/#). The username and password are located in [ansible/inventories/vagrant/group_vars/docker_swarm_manager/traefik.yml](ansible/inventories/vagrant/group_vars/docker_swarm_manager/traefik.yml)

#### Running Spec Suite

In order to run the test suite (currently):

1. Enter the Vagrant VM with `vagrant ssh`
2. Start a shell in the `finding_aid_discovery` container: 
```
  docker exec -it fad_finding_aid_discovery.1.{whatever} sh
```
3. Run `rspec` command: `RAILS_ENV=test bundle exec rspec`

#### Solr Admin

To access the Solr admin when running a development environment navigate to:
[https://finding-aid-discovery-dev.library.upenn.edu:8983/solr/#/](https://finding-aid-discovery-dev.library.upenn.edu:8983/solr/#/)
