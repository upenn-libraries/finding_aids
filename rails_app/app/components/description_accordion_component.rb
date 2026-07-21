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

  # @return [Enumerator<Blacklight::FieldPresenter>]
  def rights_and_citation
    presenter.field_presenters_by_group(:rights_and_citation)
  end

  # @return [Enumerator<Blacklight::FieldPresenter>]
  def subjects_and_headings
    presenter.field_presenters_by_group(:subjects_and_headings)
  end
end
