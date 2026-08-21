# frozen_string_literal: true

# Recursively renders hierarchical inventory using the details pattern.
class InventoryComponent < ViewComponent::Base
  ONLINE_RESOURCE = 'View Online'
  HEADING_OFFSET = 2
  HEADING_MAX = 6
  COLSPAN_MIN = 3
  COLSPAN_MAX = 4

  # @param entry [Ead::Extraction::Inventory::Entry]
  # @param level [Integer]
  # @param parent_id [String]
  # @param index [Integer]
  # @param requestable [Boolean]
  def initialize(entry:, index:, level: 1, parent_id: nil, requestable: false)
    @entry = entry
    @level = level
    @parent_id = parent_id
    @index = index
    @requestable = requestable
  end

  # @return [ActiveSupport::SafeBuffer]
  def parent_entry_metadata(entry)
    metadata = safe_join [identification_definitions(entry), links_definitions(entry)].compact_blank
    metadata_dl = content_tag(:dl, class: 'pl-dl--inline') { metadata } if metadata.present?

    safe_join([entry.descriptions, metadata_dl])
  end

  # @param entry [Ead::Extraction::Inventory::Entry]
  # @return [Array<ActiveSupport::SafeBuffer>]
  def digital_archival_object_links(entry)
    entry.digital_objects.map { |dao| link_to dao.title, dao.href, target: '_blank', rel: 'noopener' }
  end

  # @param entry [Ead::Extraction::Inventory::Entry]
  # @return [ActiveSupport::SafeBuffer, String, nil]
  def contents_column(entry)
    if entry.additional_contents?
      content_tag(:dl, class: 'pl-dl--inline fa-inventory-detail') do
        safe_join [title_definition(entry), description_definitions(entry), identification_definitions(entry),
                   links_definitions(entry)].compact_blank
      end
    else
      entry.presenter.condensed_heading
    end
  end

  # @return [String]
  def heading_id
    @entry.id(parent_id: @parent_id, index: @index)
  end

  # @return [Symbol]
  def heading_tag
    heading_level = @level + HEADING_OFFSET
    heading_level = [heading_level, HEADING_MAX].min
    "h#{heading_level}".to_sym
  end

  # @return [ActiveSupport::SafeBuffer]
  def heading
    request_span = content_tag(:span, nil, class: 'fa-visit__section-count pl-caps') if @requestable

    content_tag(heading_tag, id: heading_id) { safe_join [@entry.presenter.heading, request_span].compact_blank }
  end

  # @return [String]
  def details_class
    subseries_class = 'fa-guide__details--subseries' if @level > 1
    ['fa-guide__details', subseries_class].join(' ')
  end

  # @return [Array<Ead::Extraction::Inventory::Entry>]
  def row_entries
    @row_entries ||= @entry.children? ? @entry.children : [@entry]
  end

  # @return [Boolean]
  def all_children_have_children?
    @entry.children? && @entry.children.all?(&:children?)
  end

  # @return [Boolean]
  def in_table_of_contents?
    @level <= TableOfContentsComponent::MAX_DEPTH
  end

  private

  # @param entry [Ead::Extraction::Inventory::Entry]
  # @return [Array<ActiveSupport::SafeBuffer>]
  def title_definition(entry)
    [content_tag(:dt, I18n.t('show.sections.inventory.title')), content_tag(:dd, entry.presenter.condensed_heading)]
  end

  # @param entry [Ead::Extraction::Inventory::Entry]
  # @return [Array<ActiveSupport::SafeBuffer>]
  def description_definitions(entry)
    entry.description_definitions.flat_map do |definition|
      [content_tag(:dt, definition.term), content_tag(:dd, definition.translation)]
    end
  end

  # @param entry [Ead::Extraction::Inventory::Entry]
  # @return [Array<ActiveSupport::SafeBuffer>]
  def identification_definitions(entry)
    entry.identification_definitions.flat_map do |definition|
      [content_tag(:dt, definition.term), content_tag(:dd, definition.translation)]
    end
  end

  # @param entry [Ead::Extraction::Inventory::Entry]
  # @return [Array<ActiveSupport::SafeBuffer>]
  def links_definitions(entry)
    digital_archival_object_links(entry).flat_map do |link|
      [content_tag(:dt, ONLINE_RESOURCE), content_tag(:dd, link)]
    end
  end
end
