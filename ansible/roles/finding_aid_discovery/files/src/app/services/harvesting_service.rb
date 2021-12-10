class HarvestingService
  FILES_PER_TIME_UNIT = 6
  TIME_UNIT_IN_SECONDS = 15

  # @param [Endpoint] endpoint
  def initialize(endpoint)
    @endpoint = endpoint
    @results = { errors: [], files: [] } # FIXME: It seems like there isn't any data being added to @results[:errors]
    @documents = []
  end

  def harvest
    xml_files = @endpoint.extractor.files
    puts "Parsing #{xml_files.size} files from #{@endpoint.slug} @ #{@endpoint.url}"

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

  def parse(url, xml)
    @endpoint.parser.parse url, xml
  end

  def index_documents
    SolrService.new.add_many documents: @documents
  rescue StandardError => e
    fatal_error e.message
  end

  def save_outcomes
    if @results[:errors].any?
      fatal_error @results[:errors]
    else
      @endpoint.last_harvest_results = { date: DateTime.now,
                                         files: @results[:files] }
    end
    @endpoint.save
  end

  def send_notifications
    # TODO: send mail to endpoint.tech_contacts
  end

  private

  def error_from(file, exception)
    @results[:files] << { filename: file.url, status: :failed,
                          errors: ["Problem downloading file: #{exception.message}"] }
    Rails.logger.error "Problem parsing #{file.url}: #{exception.message}"
  end

  def document_added(file, document)
    @results[:files] << { filename: file.url, status: :ok, id: document[:id] }
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
