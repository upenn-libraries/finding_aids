class HarvestingService
  FILES_PER_TIME_UNIT = 6
  TIME_UNIT_IN_SECONDS = 30

  # @param [Endpoint] endpoint
  def initialize(endpoint)
    @endpoint = endpoint
    @indexer = endpoint.indexer
    @xml_files = endpoint.reader.new(url: endpoint.url).extract # rescue? write to last_status?
  rescue OpenURI::HTTPError => e
    fatal_error "Problem accessing endpoint: #{e.message}"
  end

  def process
    indexer_class = @endpoint.indexer

    documents = []
    results = { errors: [], files: [] }

    @xml_files.each_slice(FILES_PER_TIME_UNIT) do |files|
      files.each do |file|
        document = indexer_class.new(file, @endpoint).process
        documents << document
        sleep TIME_UNIT_IN_SECONDS
      rescue OpenURI::HTTPError => e
        results[:files] << { filename: file, status: :failed,
                             errors: ["Problem downloading file: #{e.message}"] }
      else
        results[:files] << { filename: file, status: :ok, id: document.id }
      end

    end

    begin
      SolrService.new.add_many documents: documents # too late to add to outcomes?
    rescue StandardError => e
      results[:errors] << "Problem writing documents to Solr: #{e.message}"
    end

    # debug
    # pp documents
    # pp outcomes

    if results[:errors].any?
      fatal_error results[:errors]
    else
      @endpoint.update(
        { last_harvest_results: { date: DateTime.now,
                                  files: results[:files] } }
      )
    end

    send_notifications
  end

  def send_notifications
    # TODO: send mail to endpoint.tech_contacts ?
  end

  private

  # @param [String, Array] errors
  def fatal_error(errors)
    @endpoint.update(
      { last_harvest_results: { date: DateTime.now,
                                errors: Array.wrap(errors) } }
    )
  end
end
