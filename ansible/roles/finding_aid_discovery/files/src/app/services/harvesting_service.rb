class HarvestingService
  FILES_PER_TIME_UNIT = 6
  TIME_UNIT_IN_SECONDS = 30

  # @param [Endpoint] endpoint
  def initialize(endpoint)
    @endpoint = endpoint
    @results = { errors: [], files: [] }
    @documents = []
  end

  def harvest
    endpoint_files = @endpoint.extractor
    endpoint_files.each_slice(FILES_PER_TIME_UNIT) do |files|
      files.each do |file|
        document = parse file
        @documents << document
        sleep TIME_UNIT_IN_SECONDS
      rescue OpenURI::HTTPError => e
        error_from(file, e)
      else
        document_added(file, document)
      end
    end
    index_documents
    # TODO: process_deletes
    save_outcomes
    send_notifications
  rescue OpenURI::HTTPError => e
    fatal_error "Problem extracting URLs from Endpoint URL: #{e.message}"
  end

  def parse(file)
    @endpoint.parser.parse file
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
    # TODO: send mail to endpoint.tech_contacts ?
  end

  private

  def error_from(file, exception)
    @results[:files] << { filename: file.url, status: :failed,
                          errors: ["Problem downloading file: #{exception.message}"] }
  end

  def document_added(file, document)
    @results[:files] << { filename: file.url, status: :ok, id: document[:id] }
  end

  # @param [String, Array] errors
  def fatal_error(errors)
    @endpoint.last_harvest_results = { date: DateTime.now,
                                       errors: Array.wrap(errors) }
  end
end
