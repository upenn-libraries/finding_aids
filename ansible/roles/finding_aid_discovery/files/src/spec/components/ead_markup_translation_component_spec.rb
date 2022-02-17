# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EadMarkupTranslationComponent, type: :component do
  let(:fragment) { Nokogiri::XML.fragment(xml) }

  before do
    render_inline(described_class.new(node: fragment))
  end

  context 'with formatted text' do
    context 'with a head tag' do
      let(:xml) do
        <<XML
        <parent>
          <head>Header</head>
          <p>Text</p>
        </parent>
XML
      end

      it 'converts to bolded text in a new div' do
        expect(rendered_component).to have_xpath '//div/strong'
      end
    end

    context 'with formatting from render attribute or emph node' do
      context 'with single formatting declarations' do
        let(:xml) do
          <<XML
          <parent>
            <title render="underline">Underlined</title>
            <title render="super">Superscript</title>
            <title render="sub">Subscript</title>
            <title render="bold">Bolded</title>
            <title render="italic">Italicized</title>
            <title render="smcaps">Small Caps</title>
            <title render="doublequote">Double Quotes</title>
            <title render="singlequote">Single Quotes</title>
            <emph>Italicized</emph>
          </parent>
XML
        end

        it 'applies underline markup and class accordingly' do
          expect(rendered_component).to have_xpath '//span[@class="underline"]', count: 1
        end

        it 'applies sub- and super-script markup accordingly' do
          expect(rendered_component).to have_xpath '//sup', count: 1
          expect(rendered_component).to have_xpath '//sub', count: 1
        end

        it 'applies markup for bolded text' do
          expect(rendered_component).to have_xpath '//strong', count: 1
        end

        it 'applies markup for italicized text' do
          expect(rendered_component).to have_xpath '//em', count: 2
        end

        it 'applies markup for small-caps text' do
          expect(rendered_component).to have_xpath '//span[@class="small-caps"]', count: 1
        end

        it 'wraps text with quotations accordingly' do
          expect(rendered_component).to have_xpath '//span', count: 1, text: '"Double Quotes"'
          expect(rendered_component).to have_xpath '//span', count: 1, text: "'Single Quotes'"
        end
      end

      context 'with combined formatting declarations' do
        let(:xml) do
          <<XML
            <parent>
              <titleproper render="bolditalic">Bolded and Italicized</title>
              <titleproper render="bolddoublequote">Bolded with Double Quotes</title>
              <titleproper render="boldsinglequote">Bolded with Single Quotes</title>
              <title render="boldsmcaps">Bolded Small Caps</title>
            </parent>
XML
        end

        it 'applies combined bold and italic markup accordingly' do
          expect(rendered_component).to have_xpath '//strong/em', count: 1, text: 'Bolded and Italicized'
        end

        it 'applies combined bold and small-caps markup' do
          expect(rendered_component).to have_xpath '//strong[@class="small-caps"]', count: 1
        end

        it 'wraps text with quotations accordingly' do
          expect(rendered_component).to have_xpath '//strong', count: 1, text: '"Bolded with Double Quotes"'
          expect(rendered_component).to have_xpath '//strong', count: 1, text: "'Bolded with Single Quotes'"
        end
      end
    end
  end

  context 'with list nodes' do
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

    context 'with a deflist nested in an ordered list' do
      let(:xml) do
        <<XML
          <list type="ordered">
            <item>
              <list type="deflist">
                <defitem>
                  <label>Nested Label</item>
                  <item>Nested Item</item>
                </defitem>
              </list>
            </item>
            <item>Second Item</item>
          </list>
XML
      end

      it 'converts nodes to properly reflect a nested list' do
        expect(rendered_component).to have_xpath '//ol/li[1]/dl/dt', count: 1
        expect(rendered_component).to have_xpath '//ol/li', count: 2
      end
    end
  end
end
