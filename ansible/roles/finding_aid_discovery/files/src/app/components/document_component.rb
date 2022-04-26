# frozen_string_literal: true

# custom methods for our DocumentComponent
class DocumentComponent < Blacklight::DocumentComponent
  def initialize(document: nil, presenter: nil,
                 id: nil, classes: [], component: :article, title_component: nil,
                 metadata_component: nil,
                 embed_component: nil,
                 thumbnail_component: nil,
                 counter: nil, document_counter: nil, counter_offset: 0,
                 show: false)
    super
  end

  def admin_info
    InfoSectionsComponent.new(
      title: I18n.t('sections.admin_info'),
      sections: SolrDocument::ParsedEad::ADMIN_INFO_SECTIONS,
      document: @document
    )
  end

  def other_info
    InfoSectionsComponent.new(
      title: I18n.t('sections.other_info'),
      sections: SolrDocument::ParsedEad::OTHER_SECTIONS,
      document: @document
    )
  end

  def topics
    TopicsComponent.new topics: @document.topics_hash
  end

  def collections_inventory
    CollectionsInventoryComponent.new(node: @document.parsed_ead.dsc)
  end
end
