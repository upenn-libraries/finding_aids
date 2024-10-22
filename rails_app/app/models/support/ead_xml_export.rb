# frozen_string_literal: true

module Support
  # Used with SolrDocument export format registration feature to enable exporting documents as raw EAD XML
  module EadXmlExport
    # @param [SolrDocument] document
    def self.extended(document)
      document.will_export_as(:ead, Mime[:xml])
    end

    # @return [String]
    def export_as_ead
      fetch(:xml_ss)
    end
  end
end
