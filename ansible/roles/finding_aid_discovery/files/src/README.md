# PACSCL Finding Aid Discovery site

## Setup

- clone repo
- `bundle install`
- `rails s` -> yields DB error - adjust `config/database.yml` as needed

## Loading data

### Sample Solr data (temporary)

```bash
bundle exec rake tools:index_sample_data
```

### Harvesting sample endpoints

Endpoint information is stored as CSV in `data/index_endpoints.csv` and `data/penn_aspace_endpoints.csv`. To harvest some of the endpoints in a local development environment:

1. Enter the Vagrant VM with `vagrant ssh`
2. Start a shell in the `finding_aid_discovery` container:
```
  docker exec -it fad_finding_aid_discovery.1.{whatever} sh
```
3. Run rake tasks:
```bash
bundle exec rake tools:sync_index_endpoints
bundle exec rake tools:sync_penn_aspace_endpoints
bundle exec rake tools:harvest_from endpoints=ism,wfis,ansp,lcp,cchs,pca
```
