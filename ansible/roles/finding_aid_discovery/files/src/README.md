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

### Actual harvesting endpoints

Endpoint information is stored as CSV in `data/index_endpoints.csv`.

```bash
bundle exec rake tools:sync_index_endpoints
```
