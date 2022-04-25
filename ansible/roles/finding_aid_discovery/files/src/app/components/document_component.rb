# frozen_string_literal: true

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
end
