# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ead::Extraction::ArchivalDescription do
  let(:archival_description) do
    parser = Ead::Parsing::ArchivalDescription.new(xml)
    described_class.new(parser)
  end

  describe '#author' do
    let(:xml) do
      <<~XML
        <ead>
          <eadheader>
            <filedesc>
              <titlestmt>
                <author>
                <head>Author</head>
                <p>An archivist</p>
                </author>
              </titlestmt>
            </filedesc>
          </eadheader>
        </ead>
      XML
    end

    it 'extracts the author as html without the heading' do
      expect(archival_description.author).to eq("\n        \n        <p>An archivist</p>\n        ")
    end
  end

  describe '#publisher' do
    let(:xml) do
      <<~XML
        <ead>
          <eadheader>
            <filedesc>
              <publicationstmt>
                <publisher>
                <head>Publisher</head>
                <p>University Archives</p>
                </publisher>
              </publicationstmt>
            </filedesc>
          </eadheader>
        </ead>
      XML
    end

    it 'extracts the publisher as html without the heading' do
      expect(archival_description.publisher).to eq("\n        \n        <p>University Archives</p>\n        ")
    end
  end

  describe '#sponsor' do
    let(:xml) do
      <<~XML
        <ead>
          <eadheader>
            <filedesc>
              <titlestmt>
                <sponsor>
                  <head>Sponsor</head>
                  <p>A wealthy donor.</p>
                </sponsor>
              </titlestmt>
            </filedesc>
          </eadheader>
        </ead>
      XML
    end

    it 'extracts the sponsor as html without the heading' do
      expect(archival_description.sponsor).to eq("\n          \n          <p>A wealthy donor.</p>\n        ")
    end
  end

  describe '#date' do
    let(:xml) do
      <<~XML
        <ead>
          <eadheader>
            <filedesc>
              <publicationstmt>
                <date>
                  <head>Date</head>
                  2024
                </date>
              </publicationstmt>
            </filedesc>
          </eadheader>
        </ead>
      XML
    end

    it 'extracts the date as html without the heading' do
      expect(archival_description.date).to eq("\n          \n          2024\n        ")
    end
  end

  describe '#language_note' do
    let(:xml) do
      <<~XML
        <ead>
          <archdesc>
            <did>
              <langmaterial>
                <language><p>English</p></language>
              </langmaterial>
            </did>
          </archdesc>
        </ead>
      XML
    end

    it 'extracts the language note as plain text only' do
      expect(archival_description.language_note).to eq('English')
    end
  end

  describe '#access_restrictions' do
    let(:xml) do
      <<~XML
        <ead>
          <archdesc>
            <accessrestrict>
              <head>Access Restrictions</head>
              <p>Restricted until 2050.</p>
            </accessrestrict>
            <accessrestrict>Restricted by donor.</accessrestrict>
          </archdesc>
        </ead>
      XML
    end

    it 'extracts all access restrictions as html' do
      restrictions = "\n      \n      <p>Restricted until 2050.</p>\n    Restricted by donor."
      expect(archival_description.access_restrictions).to eq restrictions
    end

    it 'does not extract the heading' do
      expect(archival_description.access_restrictions).not_to include('Access Restrictions')
    end
  end

  describe '#use_restrictions' do
    let(:xml) do
      <<~XML
        <ead>
          <archdesc>
            <userestrict>
              <head>Use Restrictions</head>
              <p>Permission required for publication.</p>
            </userestrict>
            <userestrict>Restricted by donor</userestrict>
          </archdesc>
        </ead>
      XML
    end

    it 'extracts all use restrictions as html' do
      restrictions = "\n      \n      <p>Permission required for publication.</p>\n    Restricted by donor"
      expect(archival_description.use_restrictions).to eq restrictions
    end

    it 'does not extract the heading' do
      expect(archival_description.use_restrictions).not_to include('Use Restrictions')
    end
  end

  describe '#description_definitions' do
    let(:xml) do
      <<~XML
        <ead>
          <archdesc>
            <scopecontent>
              <head>Scope and Contents</head>
              <p>Contains correspondence and photographs.</p>
            </scopecontent>
            <bioghist>
              <head>Biography</head>
              <p>Marian Anderson was born...</p>
            </bioghist>
          </archdesc>
        </ead>
      XML
    end

    it 'creates definitions for descriptive sections' do
      definitions = archival_description.description_definitions

      expect(definitions.map(&:term)).to contain_exactly('scopecontent', 'bioghist')

      expect(definitions.map(&:translation)).to include(
        "\n      \n      <p>Contains correspondence and photographs.</p>\n    ",
        "\n      \n      <p>Marian Anderson was born...</p>\n    "
      )
    end

    it 'does not include headings' do
      definitions = archival_description.description_definitions

      expect(definitions.map(&:translation)).not_to include('Scope and Contents')
    end
  end

  context 'with missing values' do
    let(:xml) { '<ead><archdesc><did/></archdesc></ead>' }

    it 'returns nil when accessrestrict is missing' do
      expect(archival_description.access_restrictions).to be_nil
    end

    it 'returns nil when userestrict is missing' do
      expect(archival_description.use_restrictions).to be_nil
    end

    it 'returns nil when author is missing' do
      expect(archival_description.author).to be_nil
    end

    it 'returns nil when sponsor is missing' do
      expect(archival_description.sponsor).to be_nil
    end

    it 'returns nil when date is missing' do
      expect(archival_description.date).to be_nil
    end

    it 'returns nil when publisher is missing' do
      expect(archival_description.publisher).to be_nil
    end

    it 'returns nil when language material is missing' do
      expect(archival_description.language_note).to be_nil
    end
  end
end
