# frozen_string_literal: true

# Renders data for one collection.
class CollectionComponent < ViewComponent::Base
  IIIF_MAINFEST_ROLE_ATTRIBUTE = 'https://iiif.io/api/presentation/2.1/'
  IDENTIFICATION_DATA_SECTIONS = %w[physdesc materialspec physloc].freeze
  DESCRIPTIVE_DATA_SECTIONS = %w[arrangement scopecontent odd relatedmaterial
                                 userestrict altformavail].freeze
  NO_TITLE = '(No Title)'

  attr_reader :node, :level, :index, :id

  def initialize(node:, level:, index:, id:, requestable: false)
    @node = node
    @level = level
    @index = index
    @id = id
    @requestable = requestable
  end

  # @return [Array]
  def digital_object_links
    @digital_object_links ||= node.xpath('./did/dao | ./dao').filter_map do |dao|
      classes = ['digital-object-link']
      classes << 'iiif-manifest-link' if dao.attr('role') == IIIF_MAINFEST_ROLE_ATTRIBUTE
      href = dao.attr('href')
      next unless href&.starts_with?('http') # rough check to ensure the value is link-like

      link_to dao.attr('title') || 'Online Resource', href,
              class: classes, target: '_blank', rel: 'noopener'
    end
  end

  def title
    @title ||= compute_title
  end

  def container_info
    @container_info ||= compute_container_info
  end

  def descriptive_data
    node.xpath(DESCRIPTIVE_DATA_SECTIONS.join(' | '))
  end

  def identification_data
    IDENTIFICATION_DATA_SECTIONS.filter_map do |section|
      if (n = node.at_xpath("did/#{section}"))
        { text: render(EadMarkupTranslationComponent.new(node: n)),
          label: n.at_xpath('@label') || t("inventory.sections.#{section}") }
      end
    end
  end

  # Checks that the item is supposed to be requestable and that there is container information. Without container
  # information a collection cannot be requestable.
  def requestable?
    @requestable && container_info.present?
  end

  def requesting_checkbox
    # TODO: ensure param safety
    name = "c#{container_info_for_checkbox}"
    id = unique_id_for_collection
    content_tag :div, class: 'custom-control custom-checkbox request-checkbox-area' do
      safe_join([check_box_tag(name, 1, false, id: id, class: 'custom-control-input request-checkbox-input',
                                               'aria-labelledby': " #{@id}-details #{@id}-title"),
                 label_tag(id, 'Toggle request', class: 'custom-control-label request-checkbox-label',
                                                 'aria-hidden': true)])
    end
  end

  # encode all container information in a way that is HTML form safe and can be extracted after submission
  def container_info_for_checkbox
    containers = container_info.map do |container_element|
      "[#{container_element[:type]}_#{container_element[:text]}]"
    end
    containers.join
  end

  # Returns true if collection node has children, otherwise returns false.
  def children?
    node.xpath('c | c01 | c02 | c03 | c04 | c05 | c06 | c07 | c08 | c09 | c10 | c11 | c12').any?
  end

  def classes
    classes = ['collection-inventory-card']
    classes << "level-#{level}"

    # Add extra styling classes if this is an end-node
    unless children?
      classes << 'end-collection'
      classes << (index.odd? ? 'dark' : 'light')
    end

    classes.join(' ')
  end

  private

  # @return [String (frozen)]
  def compute_title
    title = render EadMarkupTranslationComponent.new(node: unittitle_node)

    title = [unitid, origination, title].compact_blank.join('. ')
    title = [title, date].compact_blank.join(', ')
    title.concat '.' unless title.ends_with?('.') # always add a period
    title.concat extent

    title.presence || NO_TITLE
  end

  # @return [Array]
  def compute_container_info
    node.xpath('did/container').map do |container|
      type = container.attr(:type) || container.attr(:localtype)
      { type: type.try(:titlecase), text: container.try(:text) }
    end
  end

  # Attempt to quickly and easily generate a unique string for this collection for usage as HTML ID attr
  # @return [String]
  def unique_id_for_collection
    SecureRandom.uuid
  end

  def unitid
    node.at_xpath("did/unitid[not(@audience='internal' or @type='aspace_uri')]").try(:text)
  end

  def unittitle_node
    node.at_xpath('did/unittitle')
  end

  def origination
    node.at_xpath('did/origination').try(:text)
  end

  # extract date, preferring unitdate over unitdatestructured
  # @return [String]
  def date
    date_unstructured || date_structured
  end

  # extract bulk and non bulk dates from unitdate element
  # @return [String]
  def date_unstructured
    return if node.xpath('did/unitdate').blank?

    non_bulk_date = node.at_xpath('did/unitdate[not(@type=\'bulk\')]').try(:text)
    bulk_date = node.at_xpath('did/unitdate[@type=\'bulk\']').try(:text)

    bulk_date = "(#{bulk_date})" if bulk_date

    [non_bulk_date, bulk_date].compact_blank.join(' ')
  end

  # extract bulk and non bulk dates from ead3 unitdatestructured element
  # @return [String]
  def date_structured
    return if node.xpath('did/unitdatestructured').blank?

    non_bulk_date = format_date_structured
    bulk_date = format_date_structured(bulk: true)

    [non_bulk_date, bulk_date].compact_blank.join(' ')
  end

  # format structured date depending on the unitdatestructured type
  # @param [Boolean] bulk
  # @return [String,nil]
  def format_date_structured(bulk: false)
    predicate = bulk ? '[@type=\'bulk\']' : '[not(@type=\'bulk\')]'
    date_node = node.at_xpath("did/unitdatestructured#{predicate}")

    return if date_node.blank?

    # prefer date range
    date = date_range(date_node) || date_node.at_xpath('.//datesingle').try(:text)

    return if date.blank?

    bulk ? "(#{date})" : date
  end

  # extract range from ead3 daterange element
  # @param [[Nokogiri::XML::Node] node
  # @return [String,nil]
  def date_range(node)
    date_range = node.at_xpath('.//daterange')

    return if date_range.blank?

    from_date = date_range.at_xpath('./fromdate').try(:text)
    to_date = date_range.at_xpath('./todate').try(:text)

    return if from_date.blank? && to_date.blank?

    "#{from_date}-#{to_date}"
  end

  # @return [String]
  def extent
    extent_unstructured || extent_structured
  end

  # @return [String]
  def extent_unstructured
    extent = node.at_xpath('did/physdesc/extent').try(:text)
    extent ? " #{extent.gsub(/(\d+)\.0/, '\1')}." : ''
  end

  # @return [String]
  def extent_structured
    structured_node = node.at_xpath('did//physdescstructured')

    return '' unless structured_node

    quantity = structured_node.at_xpath('./quantity')&.text
    unit_type = structured_node.at_xpath('./unittype')&.text

    return '' unless quantity && unit_type

    extent = [quantity, unit_type].join(' ').downcase
    " #{extent.gsub(/(\d+)\.0/, '\1')}."
  end
end
