# Hardworking class to do the actual Endpoint extraction and file download, parsing and indexing
# Usage: HarvestingService.new(endpoint).harvest
class HarvestingService
  CRAWL_DELAY = 1

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
    xml_files.each do |file|
      document = parse(file.url, file.read)
      @documents << document
    rescue StandardError => e
      log_error_from(file, e)
    else
      log_document_added(file, document)
    ensure
      sleep CRAWL_DELAY
    end

    process_removals(harvested_doc_ids: @documents.collect { |doc| doc[:id] })
    index_documents
    save_outcomes
    send_notifications
  rescue OpenURI::HTTPError => e
    fatal_error "Problem extracting URLs from Endpoint URL: #{e.message}"
  end

  # @param [String] url
  # @param [String] xml_content
  def parse(url, xml_content)
    @endpoint.parser.parse url, xml_content
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
    # TODO: send mail to @endpoint.tech_contacts
  end

  private

  # @param [IndexExtractor::XMLFile] file
  # @param [Exception] exception
  def log_error_from(file, exception)
    @file_results << { filename: file.url, status: :failed,
                       errors: ["Problem downloading file: #{exception.message}"] }
    Rails.logger.error "Problem parsing #{file.url}: #{exception.message}"
  end

  # @param [IndexExtractor::XMLFile] file
  # @param [Hash] document
  def log_document_added(file, document)
    @file_results << { filename: file.url, status: :ok, id: document[:id] }
    Rails.logger.info "Parsed #{file.url} OK"
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
  end
end
