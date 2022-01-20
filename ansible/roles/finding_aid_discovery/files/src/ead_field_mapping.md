# EAD Field Mapping

Are there potentially more copy fields in the solr configuration?

| Old Solr Field Name           | New Solr Field Name | Mapping Rule | Facet? | Searchable? | Displayed In | Note |
|-------------------------------| ----- |-------------|--------|-------------| ----- |------|
| id                            | | |        |             | Index, Show | |
| format                        | | "ead"       |        |             |      | Probably not needed anymore? |
| xml                           | | | | | | | 
| email_field                   | | | | | | | 
| link_url_field                | | | | | | | 
| repository_url_field          | | | | | | | 
| creator_field                 | | | | | | | 
| title_field                   | | | | | | | 
| unitid_field                  | | | | | | | 
| prettyunitid_field            | | | | | | | 
| extent_field                  | | | | | | | 
| inclusive_date_field          | | | | | | | 
| bulk_date_field               | | | | | | | 
| abstract_scope_contents_field | | | | | | | 
| date_added_field              | | | | | | | 
| preferred_citation_field      | | | | | | | 
| repository1_field             | | | | | | | 
| repository2_field             | | | | | | | 
| repository3_field             | | | | | | | 
| top_repository_facet          | | | | | | | 
| repository_facet              | | | | | | | 
| date_facet                    | | | | | | | 
| bulk_date_facet               | | | | | | | 
| language_facet                | | | | | | | 
| name_facet                    | | | | | | | 
| subject_person_facet          | | | | | | | 
| subject_corporate_name_facet  | | | | | | | 
| creator_facet                 | | | | | | | 
| donor_facet                   | | | | | | | 
| subject_place_facet           | | | | | | | 
| subject_topic_facet           | | | | | | | 
| genre_form_facet              | | | | | | | 
| header_bucket_search          | | | | | | | 
| summary_bucket_search         | | | | | | | 
| content_bucket_search         | | | | | | | 
| union_bucket_search           | | | | | | | 

