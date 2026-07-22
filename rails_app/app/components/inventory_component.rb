# frozen_string_literal: true

# Recursively renders hierarchical inventory using the details pattern.
class InventoryComponent < ViewComponent::Base
  NO_TITLE = '(No Title)'
  ONLINE_RESOURCE = 'View Online'
  PARENT_ID = 'series'
  HEADING_OFFSET = 2
  HEADING_MAX = 6
  COLSPAN_MIN = 3
  COLSPAN_MAX = 4

  # @param entry [Ead::Extraction::Inventory::Entry]
  # @param level [Integer]
  # @param parent_id [String]
  # @param index [Integer]
  # @param requestable [Boolean]
  def initialize(entry:, index:, level: 1, parent_id: PARENT_ID, requestable: false)
    @entry = entry
    @level = level
    @parent_id = parent_id
    @index = index
    @requestable = requestable
  end

  # @return [ActiveSupport::SafeBuffer, String]
  def details_title(entry)
    title(title: entry.title_html, origination: entry.origination, date: date(entry), extent: extent_integer(entry))
  end

  # @return [ActiveSupport::SafeBuffer, String]
  def table_entry_title(entry)
    title(title: entry.title_html, origination: entry.origination)
  end

  # @param entry [Ead::Extraction::Inventory::Entry]
  # @return [String]
  def date(entry)
    non_bulk_date = entry.non_bulk_date
    bulk_date = entry.bulk_date

    return if non_bulk_date.blank? && bulk_date.blank?

    bulk_date = "(#{bulk_date})" if bulk_date

    [non_bulk_date, bulk_date].compact_blank.join(' ')
  end

  # @param entry [Ead::Extraction::Inventory::Entry]
  # @return [Array<ActiveSupport::SafeBuffer>]
  def digital_archival_object_links(entry)
    entry.digital_objects.map { |dao| link_to dao.title, dao.href, target: '_blank', rel: 'noopener' }
  end

  # @return [ActiveSupport::SafeBuffer]
  def parent_entry_metadata(entry)
    metadata = safe_join [identification_definitions(entry), links_definitions(entry)].compact_blank
    metadata_dl = content_tag(:dl, class: 'pl-dl--inline') { metadata } if metadata.present?

    safe_join([entry.descriptive_metadata, metadata_dl])
  end

  # @param entry [Ead::Extraction::Inventory::Entry]
  # @return [ActiveSupport::SafeBuffer, String, nil]
  def contents_column(entry)
    if entry.additional_contents?
      content_tag(:dl, class: 'pl-dl--inline fa-inventory-detail') do
        safe_join [title_definition(entry), descriptive_definitions(entry), identification_definitions(entry),
                   links_definitions(entry)].compact_blank
      end
    else
      table_entry_title(entry)
    end
  end

  # @return [String]
  def heading_id
    "#{@parent_id}-#{@index}"
  end

  # @return [Symbol]
  def heading_tag
    heading_level = @level + HEADING_OFFSET
    heading_level = [heading_level, HEADING_MAX].min
    "h#{heading_level}".to_sym
  end

  # @return [ActiveSupport::SafeBuffer]
  def heading
    request_span = content_tag(:span, nil, class: 'fa-visit__section-count fa-small-name') if @requestable

    content_tag(heading_tag, id: heading_id) { safe_join [details_title(@entry), request_span].compact_blank }
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

  private

  # @param entry [Ead::Extraction::Inventory::Entry]
  # @return [Array<ActiveSupport::SafeBuffer>]
  def title_definition(entry)
    definition = title(title: entry.title_html, origination: entry.origination)
    [content_tag(:dt, 'Title'), content_tag(:dd, definition)]
  end

  # @param entry [Ead::Extraction::Inventory::Entry]
  # @return [Array<ActiveSupport::SafeBuffer>]
  def descriptive_definitions(entry)
    entry.descriptive_metadata_definitions.flat_map do |metadata|
      [content_tag(:dt, metadata[:term]), content_tag(:dd, metadata[:definition])]
    end
  end

  # @param entry [Ead::Extraction::Inventory::Entry]
  # @return [Array<ActiveSupport::SafeBuffer>]
  def identification_definitions(entry)
    entry.identification_metadata_definitions.flat_map do |metadata|
      [content_tag(:dt, metadata[:term]), content_tag(:dd, metadata[:definition])]
    end
  end

  # @param entry [Ead::Extraction::Inventory::Entry]
  # @return [Array<ActiveSupport::SafeBuffer>]
  def links_definitions(entry)
    digital_archival_object_links(entry).flat_map do |link|
      [content_tag(:dt, ONLINE_RESOURCE), content_tag(:dd, link)]
    end
  end

  # @param entry [Ead::Extraction::Inventory::Entry]
  # @return [String]
  def extent_integer(entry)
    extent = entry.extent
    extent ? " #{extent.gsub(/(\d+)\.0/, '\1')}." : ''
  end

  # @param title [ActiveSupport::SafeBuffer, String]
  # @param origination [String, nil]
  # @param date [String, nil]
  # @param extent [String, nil]
  # @param unitid [String, nil]
  # @return [ActiveSupport::SafeBuffer, String]
  def title(title:, origination: nil, date: nil, extent: nil, unitid: nil)
    title = [unitid, origination, title].compact_blank.join('. ')
    title = [title, date].compact_blank.join(', ')
    title.concat extent if extent.present?

    sanitize(title.presence) || NO_TITLE
  end

  # @param entry [Ead::Extraction::Inventory::Entry]
  # @return [String]
  def join_containers(entry)
    entry.containers.map(&:to_s).join(', ')
  end
end
