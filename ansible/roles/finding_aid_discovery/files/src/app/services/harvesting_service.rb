# frozen_string_literal: true

# Hardworking class to do the actual Endpoint extraction and file download, parsing and indexing
# Usage: HarvestingService.new(endpoint).harvest
class HarvestingService
  CRAWL_DELAY = 0.2

  # @param [Endpoint] endpoint
  def initialize(endpoint, solr_service = SolrService.new)
    @endpoint = endpoint
    @file_results = []
    @documents = []
    @solr = solr_service
  end

  def harvest
    xml_files = @endpoint.extractor.files
    Rails.logger.info "Parsing #{xml_files.size} files from #{@endpoint.slug} @ #{@endpoint.url}"
    xml_files.each_with_index do |ead, i|
      validate_identifier(ead)
      document = parse(ead.id, ead.xml)
      @documents << document
      # TODO: this query is unnecessary and should be removed when the DB connection issue can be resolved.
      Endpoint.exists?(@endpoint.id) if !ENV.fetch('SKIP_FRIVOLOUS_HARVEST_QUERY', nil) && (i % 60).zero?
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

  # @param [String] file_id
  # @param [String] xml_content
  def parse(file_id, xml_content)
    @endpoint.parser.parse file_id, xml_content
  end

  # @param [Array] harvested_doc_ids
  def process_removals(harvested_doc_ids:)
    existing_record_ids = @solr.find_ids_by_endpoint(@endpoint)
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
    @endpoint.last_harvest_results = { date: DateTime.current,
                                       files: @file_results }
    @endpoint.save
  end

  def send_notifications
    HarvestNotificationMailer.with(endpoint: @endpoint)
                             .send("#{@endpoint.last_harvest.status}_harvest_notification")
                             .deliver_now # TODO: Should swap this to deliver_later when we get our job queues configured.
  end

  private

  # @param [BaseExtractor::BaseEadSource] ead
  def validate_identifier(ead)
    return unless ead.id.in? @documents.collect(&:id)

    raise StandardError, "Generated ID is not unique for #{ead.url}. Please ensure each file has a unique filename."
  end

  # @param [BaseEadFile] ead_file
  # @param [Exception] exception
  def log_error_from(ead_file, exception)
    @file_results << { id: ead_file.id, status: :failed,
                       errors: ["Problem downloading file: #{exception.message}"] }
    Rails.logger.error "Problem parsing #{ead_file.id}: #{exception.message}"
  end

  # @param [BaseEadFile] ead_file
  # @param [Hash] document
  def log_document_added(ead_file, document)
    @file_results << { status: :ok, id: document[:id] }
    Rails.logger.info "Parsed #{ead_file.id} OK"
  end

  # @param [Array<String>] ids
  def log_documents_removed(ids)
    Rails.logger.info "Deleting records for #{@endpoint.slug} not present in latest harvest: #{ids.join(', ')}"
    ids.each do |id|
      @file_results << { id: id, status: :removed }
    end
  end

  # @param [String, Array] errors
  def fatal_error(errors)
    errors = Array.wrap(errors)
    Rails.logger.error "Fatal error during harvesting: #{errors.join(', ')}"
    @endpoint.last_harvest_results = { date: DateTime.current,
                                       files: [],
                                       errors: errors }
    @endpoint.save
  end
end
