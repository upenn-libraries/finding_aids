# frozen_string_literal: true

# Hardworking class to do the actual Endpoint extraction and file download, parsing and indexing
# Usage: HarvestingService.new(endpoint).harvest
class HarvestingService
  CRAWL_DELAY = 0.2

  class IdentifierValidationError < StandardError; end

  attr_reader :file_results, :document_ids

  # @param [Endpoint] endpoint
  def initialize(endpoint, solr_service = SolrService.new, limit: nil)
    @endpoint = endpoint
    @parser = endpoint.parser
    @solr = solr_service
    @limit = limit
    @existing_record_ids = @solr.find_ids_by_endpoint(@endpoint.slug)
    @file_results = []
    @document_ids = []
  end

  def harvest
    # TODO: return some kind of indicator/error message that specifies the endpoint is inactive
    return unless @endpoint.active?

    harvest_all_files
    process_removals
    save_outcomes
  rescue StandardError => e
    fatal_error "Problem extracting URLs from Endpoint URL: #{e.message}"
  ensure
    send_notifications
  end

  # Extracts files from endpoint and harvests each one. The harvest status
  # of each file is logged and saved to the @file_results hash.
  def harvest_all_files
    xml_files = @limit.present? ? @endpoint.extractor.files.first(@limit) : @endpoint.extractor.files
    Rails.logger.info "Parsing #{xml_files.size} files from #{@endpoint.slug}"

    xml_files.each_slice(500) do |slice|
      documents = []
      slice.each do |ead|
        document = @parser.parse(ead.xml)
        validate_identifier!(ead, document[:id])
        documents << document
        document_ids << document[:id]
      rescue EadParser::ValidationError, IdentifierValidationError, StandardError => e
        log_error_from(ead, e)
      else
        log_document_added(document)
      ensure
        sleep CRAWL_DELAY
      end
      index_documents(documents)
    end
  end

  # Removes documents that are no longer present at the endpoint.
  def process_removals
    removed_ids = @existing_record_ids - document_ids
    @solr.delete_by_ids removed_ids
    log_documents_removed(removed_ids)
  end

  def index_documents(documents)
    @solr.add_many(documents: documents)
    Rails.logger.info "Indexed #{documents.length} documents"
  rescue StandardError => e
    fatal_error e.message
  end

  def save_outcomes
    @endpoint.update!(
      last_harvest_results: { date: DateTime.current, files: safe_file_results }
    )
  end

  def send_notifications
    return unless @endpoint.active?
    return if @endpoint.last_harvest.status == Endpoint::LastHarvest::COMPLETE

    HarvestNotificationMailer.with(endpoint: @endpoint)
                             .send("#{@endpoint.last_harvest.status}_harvest_notification")
                             .deliver_now
  end

  private

  # @param [BaseExtractor::BaseEadSource] ead
  # @param [String] id
  def validate_identifier!(ead, id)
    return unless id.in?(document_ids)

    raise IdentifierValidationError,
          "Generated ID is not unique for #{ead.source_id}. Please ensure each file has a unique id."
  end

  # @param [BaseExtractor::BaseEadSource] ead_file
  # @param [Exception] exception
  def log_error_from(ead_file, exception)
    Rails.logger.error "Problem parsing #{ead_file.source_id}: #{exception.message}"
    @file_results << { id: ead_file.source_id, status: :failed,
                       errors: ["Problem downloading file: #{exception.message}"] }
  end

  # @param [Hash] document
  def log_document_added(document)
    Rails.logger.info "Parsed #{document[:id]} OK"
    @file_results << { status: :ok, id: document[:id] }
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
    @endpoint.update!(
      last_harvest_results: { date: DateTime.current, files: [], errors: errors }
    )
  end

  # massage the @file_results array in case its JSON representation is too large
  # Postgres' limit for JSONB fields is ~250MB
  # @return [Array]
  def safe_file_results
    truncate_file_results_errors while @file_results.to_json.bytesize > 100_000_000
    @file_results
  end

  # iterates through file_results array, truncating the error field values by half
  def truncate_file_results_errors
    @file_results.each do |entry|
      next unless entry.key? :errors

      length = entry[:errors].try(:first).try(:length) # for a file error, errors is always single-valued
      entry[:errors] = Array.wrap(entry[:errors].try(:first).try(:truncate, length / 2))
    end
  end
end
