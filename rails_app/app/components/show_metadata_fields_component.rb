# frozen_string_literal: true

# Renders show page metadata in a description list
class ShowMetadataFieldsComponent < ViewComponent::Base
  attr_reader :fields

  LIST_LENGTH_LIMIT = 5
  HEADINGS_SECTION_ID = '#topics'

  # @param fields [Enumerator<Blacklight::FieldPresenter>]
  # @param dl_class [String]
  # @param dt_class [String, nil]
  # @param wrapper_tag [String, Symbol]
  # @param truncate [Boolean] limit displayed lists to LIST_LENGTH_LIMIT
  def initialize(fields:, dl_class: 'pl-dl', dt_class: nil, wrapper_tag: nil, truncate: false)
    @fields = fields
    @dl_class = dl_class
    @dt_class = dt_class
    @wrapper_tag = wrapper_tag
    @truncate = truncate
  end

  # @return [ActionView::OutputBuffer, ActiveSupport::SafeBuffer]
  def wrapper(&block)
    return capture(&block) unless @wrapper_tag

    content_tag(@wrapper_tag, &block)
  end

  # @param field [Blacklight::FieldPresenter]
  # @return [Array]
  def truncated_headings_list(field:)
    values = field.render
    return values if !@truncate || values.length <= LIST_LENGTH_LIMIT

    see_all_link = link_to t('show.sections.overview.see_all_entries', field: field.label), HEADINGS_SECTION_ID
    values.first(LIST_LENGTH_LIMIT - 1) << see_all_link
  end

  # @return [Boolean]
  def render?
    fields.any?
  end
end
