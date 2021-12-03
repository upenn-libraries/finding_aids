class HarvestingService
  FILES_PER_TIME_UNIT = 6
  TIME_UNIT_IN_SECONDS = 30

  # @param [Endpoint] endpoint
  def initialize(endpoint)
    @endpoint = endpoint
    @indexer = endpoint.indexer
    @xml_files = endpoint.reader.new(url: endpoint.url).extract # rescue? write to last_status?
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
      # rescue HarvestingException, ParsingException => e
      rescue StandardError => e
        results[:files] << { link: file, errors: [e.message] }
      else
        results[:files] << { id: document.id, status: :ok, link: file }
      end

    end

    begin
      SolrService.new.add_many documents # too late to add to outcomes?
    rescue StandardError => e
      results[:errors] << "Problem writing documents to Solr: #{e.message}"
    end

    # debug
    # pp documents
    # pp outcomes

    @endpoint.update({ last_harvest_results: results }) # etc...

    send_notifications
  end

  def send_notifications
    # TODO: send mail to endpoint.tech_contacts ?
  end
end
