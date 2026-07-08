# frozen_string_literal: true

# Renders show page metadata in a description list
class ShowMetadataFieldsComponent < ViewComponent::Base
  attr_reader :fields

  # @param fields [Enumerator<Blacklight::FieldPresenter>]
  # @param dl_class [String]
  # @param dt_class [String, nil]
  # @param wrapper_tag [String, Symbol]
  def initialize(fields:, dl_class: 'pl-dl', dt_class: nil, wrapper_tag: nil)
    @fields = fields
    @dl_class = dl_class
    @dt_class = dt_class
    @wrapper_tag = wrapper_tag
  end

  # @return [ActionView::OutputBuffer, ActiveSupport::SafeBuffer]
  def wrapper(&block)
    return capture(&block) unless @wrapper_tag

    content_tag(@wrapper_tag, &block)
  end

  # @return [Boolean]
  def render?
    fields.any?
  end
end
