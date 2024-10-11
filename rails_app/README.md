# Finding Aid Discovery Site

- [Overview](#overview)
  - [Endpoints](#endpoints)
  - [Generating Unique Identifiers](#generating-unique-identifiers)
  - [Harvesting](#harvesting)
    - [WebpageExtractor](#webpageextractor)
    - [ASpaceExtractor](#aspaceextractor)
    - [Notifications](#notifications)
    - [Status](#status)
  - [Sitemap](#sitemap)
  - [Robots.txt](#robotstxt)
- [Local Development Environment](#local-development-environment)
  - [Interacting with the Application](#interacting-with-the-application)
  - [Harvesting Sample Endpoints](#harvesting-sample-endpoints)
  - [Running Test Suite](#running-test-suite)
- [Rubocop](#rubocop)

## Overview
This application enables discovery of archival materials available in Philadelphia area. PACSCL members, Penn units and other regional archives make available EAD files which are then harvested and indexed by this application. Records can be harvested from a web page or from Penn Libraries' ArchivesSpace instance. Blacklight is used to facilitate discovery and display of archival information. EAD XML metadata is parsed at index and display time using a custom EAD parser. A shallow integration with Aeon facilitates requesting for certain Penn Libraries collections.

### Endpoints
Each organization providing records has a corresponding `Endpoint`. All stored information (slug, harvest config, contacts) about these endpoints is contained in the [endpoints CSV file](/ansible/roles/finding_aid_discovery/files/src/data/endpoints.csv).

When a new organization wishes to have their EADs indexed into the application they must provide:
- an endpoint slug, which can include uppercase letters and underscores
- technical contact, email
- public contact, email
- webpage url, if indexing from a webpage
- repository id, if indexing from a ArchiveSpace instance
- aspace_instance slug, if indexing from an ArchiveSpace instance

### Generating Unique Identifiers
Identifiers for each EAD are generated from the endpoint slug and unit id. The unit ids provided in each EAD should be unique for that repository. If they are not this is a problem the partner needs to rectify.

We generate the id by extracting the unit_id from `/ead/archdesc/did/unitid[not(@audience='internal')]`, removing any characters that aren't letters, numbers, period or dashes, uppercasing the value and then prefixing it with the endpoint slug followed by an underscore. The code looks something like:

```ruby
endpoint_slug = 'EXAMPLE'
unit_id = xml.at_path('/ead/archdesc/did/unitid[not(@audience='internal')]').text
"#{endpoint_slug}_#{unit_id}.gsub(/[^A-Za-z0-9.-]/, '').upcase"
```

### Harvesting

Background jobs exist to queue up and perform the harvesting operations. [`PartnerHarvestEnququeJob`](/ansible/roles/finding_aid_discovery/files/src/app/jobs/partner_harvest_enqueue_job.rb) will first synchronize the `Endpoints` stored in the application with the contents of the [endpoints CSV file](/ansible/roles/finding_aid_discovery/files/src/data/endpoints.csv), then enqueue a [`PartnerHarvestJob`](/ansible/roles/finding_aid_discovery/files/src/app/jobs/partner_harvest_job.rb) for each endpoint.

Currently two means of harvesting are supported. The means used is configured as part of the endpoint's configuration. Harvesting behavior is represented in `Extractor` classes.

> Important Note: EAD files in [EAD 3 spec](https://github.com/SAA-SDT/EAD3/tree/v1.1.1) will not be harvested. An error will be shown in the harvest outcomes if a file in EAD 3 is detected.

#### WebpageExtractor

This means of harvesting supports the legacy application style of basic HTML pages containing an index of links to EAD XML files. This extractor will parse a HTML document and pull out any `href`s that point to `.xml` files.

#### ASpaceExtractor

The ASpaceExtractor supports harvesting records directly from an ArchivesSpace instance via the ArchivesSpace API. In order to harvest from an ArchivesSpace instance:
- an `ASpaceInstance` object must be related to the `Endpoint`
- a username and password must be provided in Vault and exposed to the application as a Docker Secret

Penn Libraries ArchivesSpace is hosted by Atlas Systems. API access is performed with the `pacscl_api` ASpace user.

It is important to note that all Resources in a Repository will be harvested where `publish` is set to `true` in ArchivesSpace.

#### Notifications
Email notifications are sent to the technical contact and the product owner, Holly Mengel, when there is a partial or failed harvest. 

#### Status
The status of harvesting operation can be viewed at `/admin/endpoints` - including specific information about individual files.

### Sitemap
The sitemap is generated via the [sitemap_generator](https://github.com/kjvarga/sitemap_generator) gem. It is generated at deploy in the `docker-entrypoint.sh` script if one isn't present and it is scheduled to be regenerated after each harvest. If a harvest is completed outside of the scheduled harvest the sitemap will have to be regenerated manually in order to reflect any changes. In most cases, its fine to wait until the next scheduled sitemap generation. 

### robots.txt
The robots.txt file is generate and added to the `public` folder at deploy time. A different `robots.txt` is generated based on the environment. To manually create the `robots.txt` run: 
```ruby
bundle exec rake tools:robotstxt
```

## Local Development Environment

Our local development environment uses vagrant in order to set up a consistent environment with the required services. Please see the [root README for instructions](../../../../../README.md#development)  on how to set up this environment.

The Rails application will be available at, [https://finding-aid-discovery-dev.library.upenn.edu](https://finding-aid-discovery-dev.library.upenn.edu).

The Solr admin console will be available at, [http://finding-aid-discovery-dev.library.upenn.int/solr/#/](http://finding-aid-discovery-dev.library.upenn.int/solr/#/).

### Interacting with the Application

Once your local development environment is set up you can ssh into the vagrant box to interact with the application:

1. Enter the Vagrant VM by running `vagrant ssh` in the `/vagrant` directory
2. Start a shell in the `finding_aid_discovery` container:
```
  docker exec -it fad_finding_aid_discovery.1.{whatever} sh
```

### Harvesting Sample Endpoints

To harvest some of the endpoints in a local development environment:

1. Start a shell in the finding aids discovery app, see [interacting-with-the-application](#interacting-with-the-application)
2. Run rake tasks:
```bash
bundle exec rake tools:sync_endpoints
bundle exec rake tools:harvest_from endpoints=ISM,WFIS,ANSP,LCP,CCHS,PCA
```

### Running Test Suite

In order to run the test suite (currently):

1. Start a shell in the finding aids discovery app, see [interacting-with-the-application](#interacting-with-the-application)
2. Run `rspec` command: `RAILS_ENV=test bundle exec rspec`

## Rubocop

This application uses Rubocop to enforce Ruby and Rails style guidelines. We centralize our UPenn specific configuration in 
[upennlib-rubocop](https://gitlab.library.upenn.edu/dld/upennlib-rubocop).

If there are rubocop offenses that you are not able to fix please do not edit the rubocop configuration instead regenerate the `rubocop_todo.yml` using the following command:

```bash
rubocop --auto-gen-config  --auto-gen-only-exclude --exclude-limit 10000
```

To change our default Rubocop config please open an MR in the `upennlib-rubocop` project.
