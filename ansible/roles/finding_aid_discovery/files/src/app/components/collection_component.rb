# frozen_string_literal: true

# Renders data for one collection.
class CollectionComponent < ViewComponent::Base
  attr_reader :node, :level

  def initialize(node:, level:)
    @node = node
    @level = level
  end

  def title
    title = render EadMarkupTranslationComponent.new(node: node.at_xpath('did/unittitle'))

    title = [unitid, origination, title].delete_if(&:blank?).join('. ')
    title = [title, date].delete_if(&:blank?).join(', ')
    title.concat '.' unless title.ends_with?('.') # always add a period
    title.concat extent

    title.presence || '(No Title)'
  end

  def containers
    node.xpath('did/container').map do |container|
      { type: container.attr(:type).titlecase, text: container.try(:text) }
    end
  end

  def descriptive_data
    node.xpath('arrangement | scopecontent | odd | relatedmaterial')
  end

  private

  def unitid
    node.at_xpath('did/unitid[not(@audience=\'internal\')]').try(:text)
  end

  def origination
    node.at_xpath('did/origination').try(:text)
  end

  def date
    return if node.xpath('did/unitdate').blank?

    non_bulk_date = node.at_xpath('did/unitdate[not(@type=\'bulk\')]').try(:text)
    bulk_date = node.at_xpath('did/unitdate[@type=\'bulk\']').try(:text)

    bulk_date = "(#{bulk_date})" if bulk_date

    [non_bulk_date, bulk_date].compact.join(' ')
  end

  def extent
    extent = node.at_xpath('did/physdesc/extent').try(:text)
    extent ? " #{extent.gsub(/(\d+)\.0/, '\1')}." : ''
  end
end
