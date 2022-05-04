# PACSCL Finding Aid Discovery site

## Setup for local development

Ensure Ruby `3.0.2` is in use for this project. Lando must also be installed.

If you have already provisioned this project in the Vagrant environment, bundler is thus explicitly configured to install gem into a directory within the container. Remove or comment out the content of `.bundle/config` so that `bundle insall` can be run on your local machine. This file is not tracked by git and will need special attention if you are switching between development environments for this project.

```
bundle exec rake tools:start # initializes services and readies the DB and Solr
SOLR_URL=http://fa-disco.solr.lndo.site/solr/pacscl-fa-dev DATABASE_HOST=localhost rails s # starts the Rails server
SOLR_URL=http://fa-disco.solr.lndo.site/solr/pacscl-fa-dev DATABASE_HOST=localhost rake tools:index_sample_data # add sample data
```

Current caveats:
- can't run specs
- can't run ASpace harvesting jobs (no secrets)

### Harvesting sample endpoints

Endpoint information is stored as CSV in `data/index_endpoints.csv` and `data/penn_aspace_endpoints.csv`. To harvest some of the endpoints in a local development environment:

1. Enter the Vagrant VM with `vagrant ssh`
2. Start a shell in the `finding_aid_discovery` container:
```
  docker exec -it fad_finding_aid_discovery.1.{whatever} sh
```
3. Run rake tasks:
```bash
bundle exec rake tools:sync_endpoints
bundle exec rake tools:harvest_from endpoints=ism,wfis,ansp,lcp,cchs,pca
```
