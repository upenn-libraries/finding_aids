# frozen_string_literal: true

# Handle mapping of parsed values from the EAD to Solr field names. Used to create JSON to send to Solr.
class RecordIndexer
  attr_reader :parsed_ead, :endpoint

  # @param parsed_ead [ParsedEad]
  # @param endpoint [Endpoint]
  def initialize(parsed_ead:, endpoint:)
    @parsed_ead = parsed_ead
    @endpoint = endpoint
  end

  # @return [Hash]
  def build
    {}.tap do |doc|
      add_identifiers doc
      add_title doc
      add_repository_info doc
      add_names doc
      add_headings doc
      add_dates doc
      add_xml doc
      add_filters doc
      add_extent doc
      add_citation doc
      add_abstract doc
    end
  end

  # @param doc [Hash]
  def add_identifiers(doc)
    doc[:id] = parsed_ead.id
    doc[:legacy_ids_ssim] = parsed_ead.legacy_ids
    doc[:ead_id_ss] = parsed_ead.ead_id
    doc[:pretty_unit_id_ss] = parsed_ead.pretty_unit_id
  end

  # @param doc [Hash]
  def add_title(doc)
    doc[:title_tsi] = parsed_ead.title
  end

  # @param doc [Hash]
  def add_repository_info(doc)
    doc[:repository_ssi] = parsed_ead.repository
    doc[:repository_address_ssi] = parsed_ead.repository_address
    doc[:contact_emails_ssm] = endpoint.public_contacts
    doc[:link_url_ss] = parsed_ead.link_url
    split_repositories = parsed_ead.repository.split(':')
    doc[:repository_name_component_1_ssi] = split_repositories[0]
    doc[:repository_name_component_2_ssi] = split_repositories[1]
    doc[:repository_name_component_3_ssi] = split_repositories[2]
  end

  # @param doc [Hash]
  def add_names(doc)
    doc[:creator_ssim] = parsed_ead.creators
    doc[:people_ssim] = parsed_ead.people
    doc[:places_ssim] = parsed_ead.places
    doc[:corpnames_ssim] = parsed_ead.corp_names
    doc[:donors_ssim] = parsed_ead.donor
    doc[:names_ssim] = parsed_ead.names
  end

  # @param doc [Hash]
  def add_headings(doc)
    doc[:languages_ssim] = parsed_ead.languages
    doc[:subjects_ssim] = parsed_ead.subjects
    doc[:genre_form_ssim] = parsed_ead.genre_form
    doc[:occupations_ssim] = parsed_ead.occupations
  end

  # @param doc [Hash]
  def add_dates(doc)
    doc[:years_iim] = parsed_ead.years
    doc[:date_added_ss] = parsed_ead.date_added
    doc[:display_date_ssim] = parsed_ead.display_date
  end

  # @param doc [Hash]
  def add_xml(doc)
    doc[:xml_ss] = parsed_ead.xml
  end

  # @param doc [Hash]
  def add_filters(doc)
    doc[:endpoint_ssi] = endpoint.slug
    doc[:upenn_record_bsi] = parsed_ead.upenn_record?
    doc[:online_content_bsi] = parsed_ead.online_content?
  end

  # @param doc [Hash]
  def add_extent(doc)
    doc[:extent_ssim] = parsed_ead.extent
  end

  # @param doc [Hash]
  def add_citation(doc)
    doc[:preferred_citation_ss] = parsed_ead.preferred_citation
  end

  # @param doc [Hash]
  def add_abstract(doc)
    doc[:abstract_scope_content_ssi] = parsed_ead.abstract_scope_contents
  end
end
