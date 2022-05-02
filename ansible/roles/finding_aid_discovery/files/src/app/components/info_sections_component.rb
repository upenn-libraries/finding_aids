# frozen_string_literal: true

# component for showing a group of section information from the parsed EAD
class InfoSectionsComponent < ViewComponent::Base
  attr_accessor :sections, :title

  # @param [String] title
  # @param [Array<Symbol>] sections
  # @param [SolrDocument] document
  def initialize(title:, sections:, document:)
    @title = title
    @sections = sections
    @document = document
  end

  private

  # @param [String] section
  def nodes_for(section)
    @document.parsed_ead.try(section)
  end
end
