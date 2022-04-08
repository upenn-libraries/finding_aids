# frozen_string_literal: true

# Renders data for one collection.
class CollectionComponent < ViewComponent::Base
  DESCRIPTIVE_DATA_SECTIONS = %w[arrangement scopecontent odd relatedmaterial
                                 userestrict].freeze

  attr_reader :node, :level, :form

  def initialize(node:, level:, form: nil)
    @node = node
    @level = level
    @form = form
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
      "#{container.attr(:type).titlecase} #{container.try(:text)}"
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

  def unitid
    node.at_xpath('did/unitid[not(@audience=\'internal\')]').try(:text)
  end

  def requesting_checkbox
    container = container_info.map { |cs| cs.gsub(' ', '_') }.to_param.gsub('/', '_')
    name = "request_for_#{@level}_#{container}"
    content_tag :div, class: 'custom-control custom-checkbox mt-2' do
      safe_join([
        form&.check_box(name, { class: 'custom-control-input', include_hidden: false }, container),
        form&.label(name, 'Add to request', class: 'custom-control-label')
      ])
    end
  end

  private

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
