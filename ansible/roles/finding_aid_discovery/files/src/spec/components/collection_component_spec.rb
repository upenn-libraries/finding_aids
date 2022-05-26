# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionComponent, type: :component do
  let(:fragment) { Nokogiri::XML.fragment(xml) }

  before do
    render_inline(
      described_class.new(
        node: fragment, level: 1, index: 1, id: 'test', requestable: true
      )
    )
  end

  context 'with a single container' do
    let(:xml) do
      <<XML
      <c>
        <did>
          <container type="box">1</container>
        </did>
      </c>
XML
    end

    it 'shows a checkbox with the expected name value' do
      expect(rendered_component).to have_field 'c[Box_1]'
    end
  end

  context 'with two containers' do
    let(:xml) do
      <<XML
      <c>
        <did>
          <container type="box">1</container>
          <container type="folder">1</container>
        </did>
      </c>
XML
    end

    it 'shows a checkbox with the expected name value' do
      expect(rendered_component).to have_field 'c[Box_1][Folder_1]'
    end
  end

  context 'with three containers' do
    let(:xml) do
      <<XML
      <c>
        <did>
          <container type="drawer">1</container>
          <container type="box">1</container>
          <container type="folder">1</container>
        </did>
      </c>
XML
    end

    it 'shows a checkbox with the expected name value' do
      expect(rendered_component).to have_field 'c[Drawer_1][Box_1][Folder_1]'
    end
  end
end
