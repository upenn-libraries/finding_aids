# Hardworking class to do the actual Endpoint extraction and file download, parsing and indexing
# Usage: HarvestingService.new(endpoint).harvest
class HarvestingService
  FILES_PER_TIME_UNIT = 6
  TIME_UNIT_IN_SECONDS = 15

  # @param [Endpoint] endpoint
  def initialize(endpoint)
    @endpoint = endpoint
    @file_results = []
    @documents = []
  end

  def harvest
    xml_files = @endpoint.extractor.files
    Rails.logger.info "Parsing #{xml_files.size} files from #{@endpoint.slug} @ #{@endpoint.url}"

    xml_files.each_slice(FILES_PER_TIME_UNIT) do |files|
      files.each do |file|
        document = parse(file.url, file.read)
        @documents << document
      rescue StandardError => e
        error_from(file, e)
      else
        document_added(file, document)
      end
      sleep TIME_UNIT_IN_SECONDS
    end

    index_documents
    # TODO: process_deletes
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

  def index_documents
    SolrService.new.add_many documents: @documents
  rescue StandardError => e
    fatal_error e.message
  end

  def save_outcomes
    @endpoint.last_harvest_results = { date: DateTime.now,
                                       files: @file_results }
    @endpoint.save
  end

  def send_notifications
    # TODO: send mail to @endpoint.tech_contacts
  end

  private

  # @param [IndexExtractor::XMLFile] file
  # @param [Exception] exception
  def error_from(file, exception)
    @file_results << { filename: file.url, status: :failed,
                       errors: ["Problem downloading file: #{exception.message}"] }
    Rails.logger.error "Problem parsing #{file.url}: #{exception.message}"
  end

  # @param [IndexExtractor::XMLFile] file
  # @param [Hash] document
  def document_added(file, document)
    @file_results << { filename: file.url, status: :ok, id: document[:id] }
    Rails.logger.info "Parsed #{file.url} OK"
  end

  # @param [String, Array] errors
  def fatal_error(errors)
    errors = Array.wrap(errors)
    Rails.logger.error "Fatal error during harvesting: #{errors.join(', ')}"
    @endpoint.last_harvest_results = { date: DateTime.now,
                                       files: [],
                                       errors: errors }
  end
end
