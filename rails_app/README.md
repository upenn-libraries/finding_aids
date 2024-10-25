# Finding Aid Discovery Site

- [Overview](#overview)
- [Administration](#administration)
  - [Users](#users)
  - [Endpoints](#partner-endpoints)
    - [Configuration](#configuration)
      - [With ArchivesSpace](#with-archivesspace)
      - [Legacy](#legacy)
  - [Sitemap](#sitemap)
  - [robots.txt](#robotstxt)
- [Local Development](#local-development)
  - [Interacting with the Application](#interacting-with-the-application)
  - [Harvesting Sample Endpoints](#harvesting-sample-endpoints)
  - [Running Test Suite](#running-test-suite)
  - [Rubocop](#rubocop)

## Overview

This application enables discovery of archival materials available in Philadelphia area. PACSCL members, Penn units and other regional archives make available EAD files which are then harvested and indexed by this application. Records can be harvested from a web page or from an ArchivesSpace instance. Blacklight is used to facilitate discovery and display of archival information. EAD XML metadata is parsed at index and display time using a custom EAD parser. A shallow integration with Aeon facilitates requesting for certain Penn Libraries collections.

## Administration

The site includes a user-facing administration area available at `/admin`. PennKey users can access the admin area if their PennKey has been added to the Users table. Endpoint and ArchiveSpace connection information can be modified from within the admin interface.

### Users

Any PennKey-holding user can add another user, by PennKey, using the User Admin area. Users can also be set to "inactive" to temporarily withold access to the admin area.

### Partner Endpoints

Each organization providing records has a corresponding `Endpoint`. All information (slug, configuration, contact persons) about these endpoints is contained in the database and editable via the admin area of the site.

Endpoints can be set to be "inactive" so that they are not automatically harvested when Endpoint harvesting is run. Additionally, endpoints can be harvested on an as-needed basis using the "Run Harvest" button on the endpoint show page. Even inactive Endpoints can be harvested via the "Run Harvest" button.

> For now, all production Endpoint data can be found in the [endpoints CSV file](/ansible/roles/finding_aid_discovery/files/src/data/endpoints.csv).

#### Unique Identifiers

> Important Note: EAD files in [EAD 3 spec](https://github.com/SAA-SDT/EAD3/tree/v1.1.1) will not be harvested. An error will be shown in the harvest outcomes if a file in EAD 3 is detected.

When adding a new Endpoint, ensure that the generated identifiers for the Endpoint's records will have unique identifiers. Identifiers for each EAD are generated from the endpoint slug and unit id. If they will not be unique this is a problem the partner needs to rectify.

We generate the id by extracting the `unit_id` from `/ead/archdesc/did/unitid[not(@audience='internal')]`, removing any characters that aren't letters, numbers, period or dashes, uppercasing the value and then prefixing it with the endpoint slug followed by an underscore. The code looks something like:

```ruby
endpoint_slug = 'EXAMPLE'
unit_id = xml.at_path('/ead/archdesc/did/unitid[not(@audience="internal")]').text
"#{endpoint_slug}_#{unit_id}.gsub(/[^A-Za-z0-9.-]/, '').upcase"
```

#### Configuration

When a new organization wishes to have their EADs indexed into the application they must provide:
- An endpoint slug, which can include uppercase letters and underscores
- A technical contact email
- A public contact email
- A webpage url, if indexing from a webpage
- A repository id, if indexing from a ArchiveSpace instance. This can be found via the ASpace Admin UI.
- An aspace_instance slug, if indexing from an ArchiveSpace instance. This slug must be no more than 20 characters.

##### With ArchivesSpace

The ArchivesSpace integration supports harvesting records directly from an ArchivesSpace instance via the ArchivesSpace API. In order to harvest from an ArchivesSpace instance:
- an `ASpaceInstance` object must be related to the `Endpoint`
- a username and password must be provided in Vault and exposed to the application as a Docker Secret

It is important to note that all Resources in a Repository will be harvested where `publish` is set to `true` in ArchivesSpace.

###### `ASpaceInstance` secret configuration

ArchivesSpace credentials are stored in Penn Libraries' HashiCorp Vault, in an environment-agnostic vault `aspace_credentials`. `ASpaceInstance` application models are linked to corresponding secrets via a naming convention. The `slug` value of an `ASpaceInstance` should prefix the vault username value names `#{slug}_aspace_username` and the password as `#{slug}_aspace_password`. As mentioned above, the ASpace slug must be no more than 20 characters for this configuration to work properly.

Steps for configuring these credentials in the application environments:

1. Add appropriately-named values to the `aspace_credentials` vault.
2. Add credential names to Ansible configuration for each environment, starting with the development environment (see `ansible/inventories/vagrant/group_vars/docker_swarm_manager/finding_aid_discovery.yml`).
3. Re-provision your local Vagrant environment to read the secrets from Vault into Docker Secrets.

##### Legacy

This Endpoint configuration supports the legacy application style of basic HTML pages containing an index of links to EAD XML files. This extractor will parse a HTML document and pull out any `href`s that point to `.xml` files.

#### API Routes

The site provides a few points for API access:

1. `/api/endpoints` gives top-level information about the Endpoints in the system, the number of records and a link to retrieve all records for that endpoint
2. `/api/repostories` gives top-level information about the repositories in the system, the number of records and a link to retrieve all records for that repository
3. `/records.json?q=__SEARCH-TERM__` can be used to conduct a search and return results, in addition to facet values and search options.

All data is returned in JSON. Search and document responses make use of the [JSON::API schema](https://jsonapi.org/).

> The raw EAD XML can be viewed by appending `/ead` to any record page URL (e.g., `https://finding-aid-discovery-dev.library.upenn.edu/records/TUBLOCKSON_BC008/ead`)

#### Sitemap
The sitemap is generated via the [sitemap_generator](https://github.com/kjvarga/sitemap_generator) gem. It is generated at deploy in the `docker-entrypoint.sh` script if one isn't present and it is scheduled to be regenerated after each harvest. If a harvest is completed outside of the scheduled harvest the sitemap will have to be regenerated manually in order to reflect any changes. In most cases, its fine to wait until the next scheduled sitemap generation.

#### robots.txt
The robots.txt file is generate and added to the `public` folder at deploy time. A different `robots.txt` is generated based on the environment. To manually create the `robots.txt` run:
```ruby
bundle exec rake tools:robotstxt
```

## Local Development

Our local development environment uses vagrant in order to set up a consistent environment with the required services. Please see the [root README for instructions](../../../../../README.md#development)  on how to set up this environment.

The Rails application will be available at [https://finding-aid-discovery-dev.library.upenn.edu](https://finding-aid-discovery-dev.library.upenn.edu).

The Solr admin console will be available at [http://finding-aid-discovery-dev.library.upenn.int/solr/#/](http://finding-aid-discovery-dev.library.upenn.int/solr/#/).

### Interacting with the Application

Once your local development environment is set up you can ssh into the vagrant box to interact with the application:

1. Enter the Vagrant VM by running `vagrant ssh` in the `/vagrant` directory
2. Start a shell in the `finding_aid_discovery` container:
```
  docker exec -it fad_finding_aid_discovery.1.{whatever} sh
```

### Harvesting Sample Endpoints

To harvest some of the endpoints in a local development environment:

1. To harvest from ASpace endpoints, it is best to use the Penn GlobalProtect VPN with the `sra.vpn.upenn.edu` server. 
2. Start a shell in the finding aids discovery app, see [interacting-with-the-application](#interacting-with-the-application)
3. Run rake tasks:
```bash
bundle exec rake tools:sync_endpoints
bundle exec rake tools:harvest_from endpoints=ISM,WFIS,ANSP,LCP,CCHS,PCA
```
To harvest from all endpoints, use the `all` argument: 
```bash
bundle exec rake tools:harvest_from endpoints=all
```
The `harvest_from` task also supports a `limit` param that limits harvest of each specified endpoint to a provided integer. This makes it easier to test endpoints without having to harvest all of their records:
```bash
bundle exec rake tools:harvest_from endpoints=all limit=10
```

### Running Test Suite

In order to run the test suite (currently):

1. Start a shell in the finding aids discovery app, see [interacting-with-the-application](#interacting-with-the-application)
2. Run `rspec` command: `RAILS_ENV=test bundle exec rspec`

### Rubocop

This application uses Rubocop to enforce Ruby and Rails style guidelines. We centralize our UPenn specific configuration in
[upennlib-rubocop](https://gitlab.library.upenn.edu/dld/upennlib-rubocop).

If there are rubocop offenses that you are not able to fix please do not edit the rubocop configuration instead regenerate the `rubocop_todo.yml` using the following command:

```bash
rubocop --auto-gen-config  --auto-gen-only-exclude --exclude-limit 10000
```

To change our default Rubocop config please open an MR in the `upennlib-rubocop` project.