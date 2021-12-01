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

    json_documents = []
    outcomes = []

    @xml_files.each_slice(FILES_PER_TIME_UNIT) do |files|
      files.each do |file|
        xml_content = URI.open file
        xml_doc = Nokogiri::XML.parse xml_content
        json_documents << indexer.process(xml_doc).to_json
        sleep TIME_UNIT_IN_SECONDS
      rescue HarvestingException, ParsingException => e
        outcomes << { link: link, errors: [e.message] }
      else
        outcomes << { id: document.id, status: :ok, link: link}
      end

    end

    # TODO: Solr Writer service - POST batches of records and commit
    # SolrWriter.index json_documents # too late to add to outcomes?

    # debug
    pp json_documents
    pp outcomes

    @endpoint.update({ last_harvest_status: { date: '', files: outcomes } }) # etc...

    send_notifications
  end

  def send_notifications
    # TODO: send mail to endpoint.tech_contacts ?
  end
end
