# frozen_string_literal: true

# Renders accordion pattern containing description metadata
class DescriptionAccordionComponent < ViewComponent::Base
  attr_reader :document, :presenter

  include EadTranslating

  # @param document [SolrDocument]
  # @param presenter [Catalog::ShowDocumentPresenter]
  # @param id [String]
  def initialize(document:, presenter:, id: nil)
    @document = document
    @presenter = presenter
    @id = id
  end

  delegate :description_sections, to: :document

  # @return [Enumerator<Blacklight::FieldPresenter>]
  def rights_and_citation
    presenter.field_presenters_by_group(:rights_and_citation)
  end

  # @return [Enumerator<Blacklight::FieldPresenter>]
  def subjects_and_headings
    presenter.field_presenters_by_group(:subjects_and_headings)
  end

  # @param section [Symbol]
  # @return [ActiveSupport::SafeBuffer]
  def content(section)
    nodes = document.parsed_ead.try(section)
    safe_join(Array.wrap(nodes).map { |node| translate(node: node, remove_head: true) })
  end
end
