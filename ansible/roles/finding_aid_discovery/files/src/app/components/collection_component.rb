class CollectionComponent < ViewComponent::Base
  attr_reader :node, :level

  def initialize(node:, level:)
    @node = node
    @level = level
  end

  def title
    title = render(EadMarkupTranslationComponent.new(node: node.at_xpath('did/unittitle'))) || '(No Title)'

    if (origination = node.at_xpath('did/origination').try(:text))
      title = "#{origination}. #{title}"
    end

    if (unitid = node.at_xpath('did/unitid[not(@audience=\'internal\')]').try(:text))
      title = "#{unitid}. #{title}"
    end

    if node.xpath('did/unitdate').present?
      non_bulk_date = node.at_xpath('did/unitdate[not(@type=\'bulk\')]').try(:text)
      bulk_date = node.at_xpath('did/unitdate[@type=\'bulk\']').try(:text)

      title.concat ", #{non_bulk_date}" if non_bulk_date
      title.concat " (#{bulk_date})"    if bulk_date
    end

    title.concat '.' unless title.ends_with?('.') # always add a period

    if (extent = node.at_xpath('did/physdesc/extent').try(:text))
      title.concat " #{extent.gsub(/(\d+)\.0/, '\1')}."
    end

    title
  end

  def containers
    node.xpath('did/container').map { |container| { type: container.attr(:type).titlecase, text: container.try(:text) } }
  end

  def descriptive_data
    node.xpath('arrangement | scopecontent | odd | relatedmaterial')
  end
end
