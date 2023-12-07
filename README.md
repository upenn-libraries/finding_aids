# Finding Aid Discovery

- [Overview](#overview)
- [Development](#development)
  - [Starting](#starting)
  - [Stopping](#stopping)
  - [Destroying](#destroying)
  - [SSH](#ssh)
  - [Traefik](#traefik)
  - [Rails Application](#rails-application)
  - [Solr Admin](#solr-admin)
- [Deployment](#deployment)
  - [Staging](#staging)
  - [Production](#production)
- [Harvesting](#harvesting)

## Overview
This repository includes the infrastructure and application code that supports the PACSCL/Penn Libraries Finding Aids discovery site. Development occurs within a robust vagrant environment. Setup and initialization of this environment, as well as information about the deployed staging and production environments, is contained here. Information about the Rails app can be found [here](/ansible/roles/finding_aid_discovery/files/src/README.md).

## Development

> Caveat: the vagrant development environment has only been tested in Linux.

In order to use the integrated development environment you will need to install [Vagrant](https://www.vagrantup.com/docs/installation) [do *not* use the Vagrant version that may be available for your distro repository - explicitly follow instructions at the Vagrant homepage] and the appropriate virtualization software. If you are running Linux or Mac x86 then install [VirtualBox](https://www.virtualbox.org/wiki/Linux_Downloads), if you are using a Mac with ARM processors then install [Parallels](https://www.parallels.com/).

You may need to update the VirtualBox configuration for the creation of a host-only network. This can be done by creating a file `/etc/vbox/networks.conf` containing:

```
* 10.0.0.0/8
```

#### Starting

From the [vagrant](vagrant) directory run:


if running with Virtualbox:
```
vagrant up --provision
```

if running with Parallels:
```
vagrant up --provider=parallels --provision
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


#### Rails Application
For information about the Rails application, see the [README](/ansible/roles/finding_aid_discovery/files/src/README.md) in the Rails application root. This includes information about running the test suite, performing harvesting, development styleguide and general application information.

#### Solr Admin

Solr is running in [CloudMode](https://solr.apache.org/guide/solr/latest/deployment-guide/cluster-types.html#solrcloud-mode) which uses Apache Zookeeper to provide centralized cluster management. Additionally, [ZooNavigator](https://github.com/elkozmon/zoonavigator) is used to manage the Zookeeper cluster in deployed environments.

To access the Solr Admin UI, navigate to [http://finding-aid-discovery-dev.library.upenn.int/solr1/#/](http://finding-aid-discovery-dev.library.upenn.int/solr1/#/).

## Deployment
Gitlab automatically deploys to both our staging and production environment under certain conditions.

### Staging
Gitlab deploys to our staging server every time new code gets merged into `main`. The staging site is available at [https://pacscl-staging.library.upenn.edu/](https://pacscl-staging.library.upenn.edu/).

Code cannot be pushed directly onto `main`, new code must be merged via a merge request.

### Production
Deployments are triggered when a new git tag is created that matches [semantic versioning](https://semver.org/), (e.g., v1.0.0). Git tags should be created via the creation of a new Release in Gitlab.

In order to deploy to production:
1. Go to [https://gitlab.library.upenn.edu/dld/finding-aids/-/releases/new](https://gitlab.library.upenn.edu/dld/finding-aids/-/releases/new)
2. Create a new tag that follows semantic versioning. Please use the next tag in the sequence.
3. Relate a milestone to the release if there is one.
4. Add a release title that is the same as the tag name.
5. Submit by clicking "Create Release".

The production site is available at [https://findingaids.library.upenn.edu/](https://findingaids.library.upenn.edu/).

## Harvesting
In our production and staging environments we schedule harvesting jobs via [sidekiq-cron](https://github.com/ondrejbartas/sidekiq-cron). All endpoints are harvested on Monday, Wednesday, Friday at 5am.