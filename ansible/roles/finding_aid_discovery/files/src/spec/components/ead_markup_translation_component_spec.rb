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
        expect(page).to have_xpath '//div/strong', text: 'Header'
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
          expect(page).to have_xpath '//span[@class="underline"]', count: 1, text: 'Underline'
        end

        it 'applies sub- and super-script markup accordingly' do
          expect(page).to have_xpath '//sup', count: 1, text: 'Superscript'
          expect(page).to have_xpath '//sub', count: 1, text: 'Subscript'
        end

        it 'applies markup for bolded text' do
          expect(page).to have_xpath '//strong', count: 1, text: 'Bolded'
        end

        it 'applies markup for italicized text' do
          expect(page).to have_xpath '//em', count: 2, text: /Italicized/
        end

        it 'applies markup for small-caps text' do
          expect(page).to have_xpath '//span[@class="small-caps"]', count: 1, text: 'Small Caps'
        end

        it 'wraps text with quotations accordingly' do
          expect(page).to have_xpath '//span', count: 1, text: '"Double Quotes"'
          expect(page).to have_xpath '//span', count: 1, text: "'Single Quotes'"
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
          expect(page).to have_xpath '//strong/em', count: 1, text: 'Bolded and Italicized'
        end

        it 'applies combined bold and small-caps markup' do
          expect(page).to have_xpath '//strong[@class="small-caps"]', count: 1, text: 'Bolded Small Caps'
        end

        it 'wraps text with quotations accordingly' do
          expect(page).to have_xpath '//strong', count: 1, text: '"Bolded with Double Quotes"'
          expect(page).to have_xpath '//strong', count: 1, text: "'Bolded with Single Quotes'"
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
        expect(page).to have_xpath '//dl/dt', count: 2, text: /Label/
        expect(page).to have_xpath '//dl/dd', count: 2, text: /Content/
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
        expect(page).to have_xpath '//ul/li', count: 3, text: /Item/
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
        expect(page).to have_xpath '//ol/li', count: 4, text: /Item/
      end
    end

    context 'with a deflist nested in an ordered list' do
      let(:xml) do
        <<XML
          <list type="ordered">
            <item>
              <list type="deflist">
                <defitem>
                  <label>Nested Label</label>
                  <item>Nested Item</item>
                </defitem>
              </list>
            </item>
            <item>Second Item</item>
          </list>
XML
      end

      it 'converts nodes to properly reflect a nested list' do
        expect(page).to have_xpath '//ol/li[1]/dl/dt', count: 1, text: /Label/
        expect(page).to have_xpath '//ol/li', count: 2, text: /Item/
      end
    end
  end

  context 'with extref tags' do
    let(:xml) do
      <<XML
        <item>
          <extref>This is a extref with no href</extref>
          <extref actuate="onRequest" show="new" title="EAD2 tag" href="https://www.extref.old">
          This is a link</extref> in EAD2 spec.
        </item>
XML
    end

    it 'converts them to HTML <a> tags with href attribute' do
      expect(page).to have_xpath '//a[@href="https://www.extref.old" and @rel="noopener"]',
                                 text: 'This is a link'
    end
  end
end
