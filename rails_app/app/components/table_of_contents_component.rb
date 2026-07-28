# frozen_string_literal: true

# Renders table of contents for record page
class TableOfContentsComponent < ViewComponent::Base
  MAX_DEPTH = 3

  attr_reader :document, :presenter, :entries, :depth

  # @param document [SolrDocument]
  # @param presenter [Blacklight::DocumentPresenter]
  # @param entries [Array<Ead::Extraction::Inventory::Entry>]
  def initialize(document:, presenter:, entries:, depth: MAX_DEPTH)
    @document = document
    @presenter = presenter
    @entries = entries
    @depth = depth
  end

  # @return [ActiveSupport::SafeBuffer]
  def inventory_list
    content_tag(:ul) do
      safe_join(entries.each_with_index.map do |entry, i|
        entry_list_item(entry: entry, index: i + 1, level: 1)
      end)
    end
  end

  private

  # @param entry [Ead::Extraction::Inventory::Entry]
  # @param parent_id [String]
  # @param index [Integer]
  # @param level [Integer]
  # @return [ActiveSupport::SafeBuffer]
  def entry_list_item(entry:, index:, level:, parent_id: nil)
    entry_id = entry.id(parent_id: parent_id, index: index)
    children = entry_children(entry: entry, parent_id: entry_id, level: level + 1) if level < depth

    content_tag(:li) do
      safe_join([link_to(entry.presenter.heading, "##{entry_id}"), children].compact)
    end
  end

  # @param entry [Ead::Extraction::Inventory::Entry]
  # @param parent_id [String]
  # @param level [Integer]
  # @return [ActiveSupport::SafeBuffer, nil]
  def entry_children(entry:, parent_id:, level:)
    return unless entry.children?

    children = entry.children.each_with_index.filter_map do |child, i|
      next unless child.children?

      entry_list_item(entry: child, parent_id: parent_id, index: i + 1, level: level)
    end

    return if children.empty?

    content_tag(:ul) { safe_join(children) }
  end
end
