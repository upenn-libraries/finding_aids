# frozen_string_literal: true

# Renders data for one collection.
class CollectionComponent < ViewComponent::Base
  DESCRIPTIVE_DATA_SECTIONS = %w[arrangement scopecontent odd relatedmaterial
                                 userestrict].freeze

  attr_reader :node, :level, :index

  def initialize(node:, level:, index:, requestable: false)
    @node = node
    @level = level
    @index = index
    @requestable = requestable
  end

  def title
    title = render EadMarkupTranslationComponent.new(node: unittitle_node)

    title = [unitid, origination, title].compact_blank.join('. ')
    title = [title, date].compact_blank.join(', ')
    title.concat '.' unless title.ends_with?('.') # always add a period
    title.concat extent

    title.presence || '(No Title)'
  end

  def container_info
    node.xpath('did/container').map do |container|
      { type: container.attr(:type).titlecase, text: container.try(:text) }
    end
  end

  def descriptive_data
    node.xpath(DESCRIPTIVE_DATA_SECTIONS.join('|'))
  end

  # @return [Hash{Symbol->String}]
  def physdesc
    physdesc_node = node.at_xpath('did/physdesc')
    return nil unless physdesc_node

    { text: render(EadMarkupTranslationComponent.new(node: physdesc_node)),
      label: physdesc_node.at_xpath('@label') }
  end

  def requesting_checkbox
    # TODO: ensure param safety
    # TODO: check that there is container information before rendering checkbox
    name = "c#{container_info_for_checkbox}"
    content_tag :div do
      safe_join([check_box_tag(name, 1),
                 label_tag(name, 'Add to request', class: 'sr-only')])
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

  def unitid
    node.at_xpath('did/unitid[not(@audience=\'internal\')]').try(:text)
  end

  def unittitle_node
    node.at_xpath('did/unittitle')
  end

  def origination
    node.at_xpath('did/origination').try(:text)
  end

  def date
    return if node.xpath('did/unitdate').blank?

    non_bulk_date = node.at_xpath('did/unitdate[not(@type=\'bulk\')]').try(:text)
    bulk_date = node.at_xpath('did/unitdate[@type=\'bulk\']').try(:text)

    bulk_date = "(#{bulk_date})" if bulk_date

    [non_bulk_date, bulk_date].compact_blank.join(' ')
  end

  def extent
    extent = node.at_xpath('did/physdesc/extent').try(:text)
    extent ? " #{extent.gsub(/(\d+)\.0/, '\1')}." : ''
  end
end
