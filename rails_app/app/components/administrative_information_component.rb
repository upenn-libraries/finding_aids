# frozen_string_literal: true

# Renders administrative information area on record show page
class AdministrativeInformationComponent < ViewComponent::Base
  attr_accessor :sections, :document

  # @param [Array<Symbol>] sections
  # @param [SolrDocument] document
  def initialize(sections:, document:)
    @sections = sections
    @document = document
  end

  def render?
    sections.any?
  end

  def info_list
    sections.map do |section|
      nodes = Array.wrap(@document.parsed_ead.try(section))
      next if nodes.blank?

      values = nodes.map { |node| render EadMarkupTranslationComponent.new(node: node, remove_head: true) }

      content_tag(:dt, I18n.t(section, scope: :sections)) + safe_join(values.map { |v| content_tag(:dd, v) })
    end
  end

  def call
    content_tag :dl, safe_join(info_list)
  end
end
