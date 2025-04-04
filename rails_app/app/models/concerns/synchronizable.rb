# frozen_string_literal: true

# Concern that adds the ability to synchronize endpoints from a CSV.
module Synchronizable
  extend ActiveSupport::Concern

  CSV_REQUIRED_HEADERS = %w[slug source_type tech_contact public_contact webpage_url aspace_repo_id
                            aspace_instance aspace_instance_url].freeze

  class_methods do
    # Adds, removes and update endpoints based on the data provided in the CSV. Endpoints that are not present in the
    # CSV but present in the database are deleted along with any documents associated with that endpoint.
    def sync_from_csv(path_to_csv, solr: SolrService.new)
      # Read CSV data and do some basic validation.
      csv = read_csv(path_to_csv)

      # Get current inventory for diffing later
      current_endpoint_slugs = Endpoint.all.pluck(:slug)

      # Get or build objects
      endpoints = csv&.map do |attr|
        endpoint = find_or_initialize_by(slug: attr['slug'])
        endpoint.public_contacts = Array.wrap(attr['public_contact'])
        endpoint.tech_contacts = Array.wrap(attr['tech_contact'])
        endpoint.source_type = attr['source_type']
        endpoint.webpage_url = attr['webpage_url']
        endpoint.aspace_repo_id = attr['aspace_repo_id']
        endpoint.aspace_instance = nil
        append_aspace_instance(endpoint, attr) if attr['aspace_instance']
        endpoint
      end

      # Update or create records, if any errors happen abort all changes.
      transaction { endpoints&.each(&:save!) }

      # Process removals
      new_endpoint_slugs = endpoints.map(&:slug)
      diff = current_endpoint_slugs - new_endpoint_slugs
      diff&.each do |endpoint_slug_to_remove|
        Rails.logger.info "Removing the following endpoint: #{endpoint_slug_to_remove}"
        Endpoint.find_by(slug: endpoint_slug_to_remove)&.destroy!
        solr.delete_by_endpoint(endpoint_slug_to_remove)
      end
    end

    # Read CSV data and do some basic validation.
    def read_csv(path)
      csv = CSV.parse(File.read(path), headers: true, strip: true)
      raise 'CSV does not match required headers' unless csv.headers.sort == CSV_REQUIRED_HEADERS.sort
      raise 'CSV does not contain data' if csv.empty?

      csv
    rescue CSV::MalformedCSVError => e
      raise "Error parsing CSV on line #{e.line_number}"
    rescue Errno::ENOENT
      raise "Cannot read CSV file at #{path}."
    end

    # @param [Endpoint] endpoint
    # @param [Hash] attr
    def append_aspace_instance(endpoint, attr)
      instance = ASpaceInstance.find_by(slug: attr['aspace_instance'])
      if instance.blank?
        instance = ASpaceInstance.create! slug: attr['aspace_instance'], base_url: attr['aspace_instance_url']
      end
      endpoint.aspace_instance = instance
    end
  end
end
