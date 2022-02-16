# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EadMarkupTranslationComponent, type: :component do
  context 'with list nodes' do
    let(:fragment) { Nokogiri::XML.fragment(xml) }

    before do
      render_inline(described_class.new(node: fragment))
    end

    context 'with deflist type' do
      let(:xml) do
        <<XML
          <list type="deflist">
            <head>Definition List</head>
            <listhead>
              <head01>Term</head01>
              <head02>Definition</head02>
            </listhead>
            <defitem>
              <label>Label I</label>
              <item>Some Content</item>
            </defitem>
            <defitem>
              <label>Label II</label>
              <item>Different Content</item>
            </defitem>
          </list>
XML
      end

      it 'converts nodes to proper definition list structure' do
        expect(rendered_component).to have_xpath '//dl/dt', count: 2
        expect(rendered_component).to have_xpath '//dl/dd', count: 2
      end
    end

    context 'with unordered type' do
      let(:xml) do
        <<XML
          <list type="unordered">
            <item>This Item</item>
            <item>That Item</item>
            <item>Another Item</item>
          </list>
XML
      end

      it 'converts nodes to proper unordered list structure' do
        expect(rendered_component).to have_xpath '//ul/li', count: 3
      end
    end

    context 'with ordered type' do
      let(:xml) do
        <<XML
          <list type="ordered">
            <item>First Item</item>
            <item>Second Item</item>
            <item>Third Item</item>
            <item>Fourth Item</item>
          </list>
XML
      end

      it 'converts nodes to proper ordered list structure' do
        expect(rendered_component).to have_xpath '//ol/li', count: 4
      end
    end

    context 'with a nested list' do
      let(:xml) do
        <<XML
          <list type="ordered">
            <item>
              <list type="unordered">
                <item>Nested Item</item>
              </list>
            </item>
            <item>Second Item</item>
          </list>
XML
      end

      it 'converts nodes to properly reflect a nested list' do
        expect(rendered_component).to have_xpath '//ol/li[1]/ul/li', count: 1
        expect(rendered_component).to have_xpath '//ol/li', count: 2
      end
    end
  end
end
