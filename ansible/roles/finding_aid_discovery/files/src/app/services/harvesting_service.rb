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
    indexer = @endpoint.indexer

    documents = []
    outcomes = []

    @xml_files.each_slice(FILES_PER_TIME_UNIT) do |files|
      files.each do |file|
        xml_content = URI.open file
        xml_doc = Nokogiri::XML.parse xml_content
        document = indexer.new(file, @endpoint).process(xml_doc)
        documents << document
        sleep TIME_UNIT_IN_SECONDS
      # rescue HarvestingException, ParsingException => e
      rescue StandardError => e
        outcomes << { link: file, errors: [e.message] }
      else
        outcomes << { id: document['id'], status: :ok, link: file }
      end

    end

    # TODO: Solr Writer service - POST batches of records and commit

    begin
      SolrService.new.add_many documents # too late to add to outcomes?
    rescue StandardError => e
      pp e
      # TODO: top level outcome error
    end

    # debug
    # pp documents
    # pp outcomes

    @endpoint.update({ last_harvest_results: { date: DateTime.now.to_s,
                                               files: outcomes } }) # etc...

    send_notifications
  end

  def send_notifications
    # TODO: send mail to endpoint.tech_contacts ?
  end
end
