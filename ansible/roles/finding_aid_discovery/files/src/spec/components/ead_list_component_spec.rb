# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EadListComponent, type: :component do
  # it 'does not render component if list_node is nil' do
  #   render_inline(described_class.new(list_node: nil))
  #
  #   expect(rendered_component).to be_blank
  # end

  context 'renders' do
    let(:xml) { file_fixture('ead/penn_museum_ead_1.xml').read }
    let(:doc) do
      doc = Nokogiri::XML(xml)
      doc.remove_namespaces!
      doc
    end

    context 'deflist' do
      let(:node) { doc.at_xpath("/ead/archdesc/arrangement/list[@type='deflist']") }

      it 'using appropriate HTML markup' do
        render_inline(described_class.new(list_node: node))
        expect(rendered_component).to have_text 'Definition List'
      end
    end
  end
end
