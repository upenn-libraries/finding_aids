# frozen_string_literal: true

# Hardworking class to do the actual Endpoint extraction and file download, parsing and indexing
# Usage: HarvestingService.new(endpoint).harvest
class HarvestingService
  CRAWL_DELAY = 0.2

  # @param [Endpoint] endpnt
  def initialize(endpnt, solr_service = SolrService.new)
    # Extracting values from endpoint so we don't keep the db connection open while we process all the EADs.
    @slug = endpnt.slug
    @parser = endpnt.parser
    @file_results = []
    @documents = []
    @solr = solr_service
  end

  def harvest
    xml_files = endpoint.extractor.files
    Rails.logger.info "Parsing #{xml_files.size} files from #{@slug}"

    xml_files.each do |ead|
      validate_identifier(ead)
      document = @parser.parse(ead.id, ead.xml)
      @documents << document
    rescue StandardError => e
      log_error_from(ead, e)
    else
      log_document_added(ead, document)
    ensure
      sleep CRAWL_DELAY
    end
    process_removals(harvested_doc_ids: @documents.pluck(:id))
    index_documents
    save_outcomes
    send_notifications
  rescue StandardError => e
    fatal_error "Problem extracting URLs from Endpoint URL: #{e.message}"
    send_notifications
  end

  # Fetching endpoint object only as it is needed. Long running harvests trigger PG::ConnectionBad errors
  # that are only resolved by reconnecting to the database.
  # For more information: https://gitlab.library.upenn.edu/pacscl/finding-aid-discovery/-/issues/36
  def endpoint
    retried = false
    begin
      endpnt = Endpoint.find_by(slug: @slug)
    rescue ActiveRecord::StatementInvalid => e
      raise e if retried

      Rails.logger.error "Reconnecting to db and retrying db query after error: #{e.message}"
      ActiveRecord::Base.connection.reconnect!
      retried = true
      retry
    end
    endpnt
  end

  # @param [Array] harvested_doc_ids
  def process_removals(harvested_doc_ids:)
    existing_record_ids = @solr.find_ids_by_endpoint(@slug)
    removed_ids = existing_record_ids - harvested_doc_ids
    @solr.delete_by_ids removed_ids
    log_documents_removed(removed_ids)
  end

  def index_documents
    SolrService.new.add_many documents: @documents
  rescue StandardError => e
    fatal_error e.message
  end

  def save_outcomes
    endpoint.update!(
      last_harvest_results: { date: DateTime.current, files: @file_results }
    )
  end

  def send_notifications
    HarvestNotificationMailer.with(endpoint: endpoint)
                             .send("#{endpoint.last_harvest.status}_harvest_notification")
                             .deliver_now # TODO: Should swap this to deliver_later when we get our job queues configured.
  end

  private

  # @param [BaseExtractor::BaseEadSource] ead
  def validate_identifier(ead)
    return unless ead.id.in?(@documents.collect { |doc| doc['id'] })

    raise StandardError, "Generated ID is not unique for #{ead.url}. Please ensure each file has a unique filename."
  end

  # @param [BaseEadFile] ead_file
  # @param [Exception] exception
  def log_error_from(ead_file, exception)
    Rails.logger.error "Problem parsing #{ead_file.id}: #{exception.message}"
    @file_results << { id: ead_file.id, status: :failed,
                       errors: ["Problem downloading file: #{exception.message}"] }
  end

  # @param [BaseEadFile] ead_file
  # @param [Hash] document
  def log_document_added(ead_file, document)
    Rails.logger.info "Parsed #{ead_file.id} OK"
    @file_results << { status: :ok, id: document[:id] }
  end

  # @param [Array<String>] ids
  def log_documents_removed(ids)
    Rails.logger.info "Deleting records for #{@slug} not present in latest harvest: #{ids.join(', ')}"
    ids.each do |id|
      @file_results << { id: id, status: :removed }
    end
  end

  # @param [String, Array] errors
  def fatal_error(errors)
    errors = Array.wrap(errors)
    Rails.logger.error "Fatal error during harvesting: #{errors.join(', ')}"
    endpoint.update!(
      last_harvest_results: { date: DateTime.current, files: [], errors: errors }
    )
  end
end
