# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ead::Parsing::ArchivalDescription do
  let(:parser) { described_class.new(xml) }

  describe '#did' do
    let(:xml) do
      <<~XML
        <ead>
          <archdesc>
            <did>
              <unittitle>Collection</unittitle>
            </did>
          </archdesc>
        </ead>
      XML
    end

    it 'returns the did node' do
      expect(parser.did.name).to eq('did')
    end

    it 'returns nil when did is missing' do
      parser = described_class.new('<ead><archdesc/></ead>')
      expect(parser.did).to be_nil
    end
  end

  describe '#dsc' do
    let(:xml) do
      <<~XML
        <ead>
          <archdesc>
            <dsc/>
          </archdesc>
        </ead>
      XML
    end

    it 'returns the dsc node' do
      expect(parser.dsc.name).to eq('dsc')
    end

    it 'returns nil when dsc is missing' do
      parser = described_class.new('<ead><archdesc/></ead>')
      expect(parser.dsc).to be_nil
    end
  end

  describe '#sponsor' do
    let(:xml) do
      <<~XML
        <ead>
          <eadheader>
            <filedesc>
              <titlestmt>
                <sponsor>Some Sponsor</sponsor>
              </titlestmt>
            </filedesc>
          </eadheader>
        </ead>
      XML
    end

    it 'returns the sponsor node' do
      expect(parser.sponsor.name).to eq('sponsor')
      expect(parser.sponsor.text).to eq('Some Sponsor')
    end

    it 'returns nil when the sponsor is missing' do
      parser = described_class.new('<ead><eadheader><filedesc/></eadheader></ead>')
      expect(parser.sponsor).to be_nil
    end
  end

  describe '#author' do
    let(:xml) do
      <<~XML
        <ead>
          <eadheader>
            <filedesc>
              <titlestmt>
                <author>Some Author</author>
              </titlestmt>
            </filedesc>
          </eadheader>
        </ead>
      XML
    end

    it 'returns the author node' do
      expect(parser.author.name).to eq('author')
      expect(parser.author.text).to eq('Some Author')
    end

    it 'returns nil when the author is missing' do
      parser = described_class.new('<ead><eadheader><filedesc/></eadheader></ead>')
      expect(parser.author).to be_nil
    end
  end

  describe '#publisher' do
    let(:xml) do
      <<~XML
        <ead>
          <eadheader>
            <filedesc>
              <publicationstmt>
                <publisher>Some Publisher</publisher>
              </publicationstmt>
            </filedesc>
          </eadheader>
        </ead>
      XML
    end

    it 'returns the publisher node' do
      expect(parser.publisher.name).to eq('publisher')
      expect(parser.publisher.text).to eq('Some Publisher')
    end

    it 'returns nil when the publisher is missing' do
      parser = described_class.new('<ead><eadheader><filedesc/></eadheader></ead>')
      expect(parser.publisher).to be_nil
    end
  end

  describe '#date' do
    let(:xml) do
      <<~XML
        <ead>
          <eadheader>
            <filedesc>
              <publicationstmt>
                <date>2024</date>
              </publicationstmt>
            </filedesc>
          </eadheader>
        </ead>
      XML
    end

    it 'returns the publication date node' do
      expect(parser.date.name).to eq('date')
      expect(parser.date.text).to eq('2024')
    end

    it 'returns nil when the date is missing' do
      parser = described_class.new('<ead><eadheader><filedesc/></eadheader></ead>')
      expect(parser.date).to be_nil
    end
  end

  describe '#langmaterial' do
    let(:xml) do
      <<~XML
        <ead>
          <archdesc>
            <did>
              <langmaterial>English</langmaterial>
            </did>
          </archdesc>
        </ead>
      XML
    end

    it 'returns the langmaterial node' do
      expect(parser.langmaterial.text).to eq('English')
      expect(parser.langmaterial.name).to eq('langmaterial')
    end

    it 'returns nil when langmaterial is missing' do
      parser = described_class.new('<ead><archdesc><did/></archdesc></ead>')
      expect(parser.langmaterial).to be_nil
    end
  end

  describe '#descriptions' do
    let(:xml) do
      <<~XML
        <ead>
          <archdesc>
            <bioghist/>
            <scopecontent/>
            <odd/>
          </archdesc>
        </ead>
      XML
    end

    it 'returns all descriptive sections' do
      expect(parser.descriptions.map(&:name)).to contain_exactly('bioghist', 'scopecontent', 'odd')
    end

    it 'returns an empty array when none exist' do
      parser = described_class.new('<ead><archdesc/></ead>')
      expect(parser.descriptions).to be_empty
    end
  end

  describe 'dynamic section methods' do
    let(:xml) do
      <<~XML
        <ead>
          <archdesc>
            <accessrestrict>Access Restrictions</accessrestrict>
            <userestrict>Use Restrictions</userestrict>
            <bioghist>Biological/History</bioghist>/
            <scopecontent>Scope/Contents</scopecontent>
          </archdesc>
        </ead>
      XML
    end

    dynamic_sections = described_class::DESCRIPTION_SECTIONS + described_class::ACCESS_SECTIONS

    dynamic_sections.each do |section|
      it "defines ##{section}" do
        expect(parser).to respond_to(section)
      end
    end

    it 'returns matching nodes for access sections' do
      expect(parser.accessrestrict.first.name).to eq('accessrestrict')
      expect(parser.userestrict.first.name).to eq('userestrict')
    end

    it 'returns matching nodes for descriptive sections' do
      expect(parser.bioghist.first.name).to eq('bioghist')
      expect(parser.scopecontent.first.name).to eq('scopecontent')
    end

    it 'returns an empty nodeset when a section is absent' do
      expect(parser.relatedmaterial).to be_empty
    end
  end

  describe 'namespace handling' do
    let(:xml) do
      <<~XML
        <ead xmlns="some-namespace">
          <archdesc>
            <did>
              <unittitle>Collection</unittitle>
            </did>
          </archdesc>
        </ead>
      XML
    end

    it 'removes namespaces during parsing' do
      expect(parser.did.name).to eq('did')
      expect(parser.did.at_xpath('unittitle').text).to eq('Collection')
    end
  end
end
