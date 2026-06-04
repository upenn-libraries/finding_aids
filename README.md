# Finding Aid Discovery

- [Overview](#overview)
- [Development](#development)
  - [Requirements](#requirements)
  - [Starting the environment](#starting-the-environment)
  - [Docker context](#docker-context)
  - [Accessing the app container](#accessing-the-app-container)
  - [Rails application](#rails-application)
  - [Solr Admin](#solr-admin)
- [Deployment](#deployment)
  - [Staging](#staging)
  - [Production](#production)
- [Harvesting](#harvesting)

## Overview

This repository contains the infrastructure and application code for the PACSCL/Penn Libraries Finding Aids discovery site.

Development is done in a Docker-based environment managed by Taskfile. This README covers setup and deployment details for development, staging, and production.

For Rails app-specific documentation, see [rails_app/README.md](/rails_app/README.md).

## Development

The development environment uses Taskfile and Docker. Running `task up` creates a Docker container that executes Ansible provisioning tasks.

### Requirements

1. Install [Task](https://taskfile.dev/) (`go-task`):
   - **Linux:** Follow the [Task installation instructions](https://taskfile.dev/docs/installation) for your package manager.
   - **macOS:** `brew install go-task`

2. Install Docker:
   - **macOS:** [Install Docker Desktop](https://docs.docker.com/desktop/install/mac-install/).  
     You should also request access to the Penn Libraries Docker Team license via [IT Helpdesk](https://ithelp.library.upenn.edu/support/home) for full functionality.
   - **Linux:** [Install Docker Engine](https://docs.docker.com/engine/install/).

### Starting the environment

1. Change to the `.dev` directory:
   ```bash
   cd .dev
   ```

2. Start the environment:
   ```bash
   task up
   ```

   On first run, Task will fetch remote taskfiles and prompt for confirmation (`Y`).

   During startup, you may be prompted for:
    - your local machine password (to update `/etc/hosts`)
    - your LDAP credentials (to retrieve secrets from HashiCorp Vault)

3. After provisioning finishes, verify the app is running at:  
   [https://finding-aid-discovery-dev.library.upenn.edu/](https://finding-aid-discovery-dev.library.upenn.edu/)

### Docker context

When the environment is running, switch Docker context to the app environment:
```bash
task docker:context:use:app
```
After switching, local Docker commands (for example, `docker ps`) operate against the development environment.

When finished, switch back to your default context:
```bash
task docker:context:use:default
```
### Accessing the app container

Once your environment is set up:

1. Switch Docker context (see [Docker context](#docker-context)):
   ```bash
   task docker:context:use:app
   ```

2. Open a shell in the app container:
   ```bash
   docker exec -it fad_finding_aid_discovery.1.{container-id} sh
   ```

## Rails application

For Rails application details (tests, harvesting tasks, style guide, and general app development), see [rails_app/README.md](/rails_app/README.md).

## Solr Admin

Solr runs in [SolrCloud mode](https://solr.apache.org/guide/solr/latest/deployment-guide/cluster-types.html#solrcloud-mode), using Apache ZooKeeper for centralized cluster management.

[ZooNavigator](https://github.com/elkozmon/zoonavigator) is used to manage ZooKeeper in deployed environments.

Access Solr Admin at:  
[http://finding-aid-discovery-dev.library.upenn.int/solr/#/](http://finding-aid-discovery-dev.library.upenn.int/solr/#/)

## Deployment

GitLab deploys to staging and production under specific conditions.

### Staging

- GitLab deploys to staging whenever new code is merged into `main`.
- Staging URL: [https://findingaids-staging.library.upenn.edu/](https://findingaids-staging.library.upenn.edu/)
- Direct pushes to `main` are not allowed; changes must be merged via merge request.

### Production

Production deployments are triggered by creating a Git tag that matches [Semantic Versioning](https://semver.org/) (for example, `v1.0.0`).

Create production tags by creating a new GitLab Release:

1. Go to [Create Release](https://gitlab.library.upenn.edu/dld/finding-aids/-/releases/new)
2. Create the next semantic version tag in sequence.
3. Associate a milestone (if applicable).
4. Set the release title to match the tag.
5. Click **Create Release**.

Production URL: [https://findingaids.library.upenn.edu/](https://findingaids.library.upenn.edu/)

## Harvesting

Harvesting jobs are scheduled with [sidekiq-cron](https://github.com/ondrejbartas/sidekiq-cron):

- **Production:** Monday, Wednesday, Friday at 5:00 AM
- **Staging:** Monday, Wednesday, Friday at 1:00 AM

Schedule configuration lives in `rails_app/config/schedule.yml`.
