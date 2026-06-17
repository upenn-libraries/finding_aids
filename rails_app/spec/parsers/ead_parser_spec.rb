# frozen_string_literal: true

require 'rails_helper'

describe EadParser do
  subject(:parser) { described_class.new xml, endpoint }

  let(:endpoint) { build(:endpoint, :webpage_harvest) }

  describe '#to_years_array', pending: 'need to move to Indexers::Record specs' do
    it 'handles @normal attribute range' do
      expect(parser.to_years_array('1875/1900')).to match_array 1875..1900
    end

    it 'handles simple ranges' do
      expect(parser.to_years_array('1875-1900')).to match_array 1875..1900
      expect(parser.to_years_array('1875 - 1900')).to match_array 1875..1900
    end

    it 'handles pseudo-endless range' do
      expect(parser.to_years_array('1809-9999')).to match_array 1809..Time.zone.now.year.to_i
    end

    it 'handles multiple present ranges' do
      expect(parser.to_years_array('1875-1905, 1905-1910')).to match_array 1875..1910
    end

    it 'handles ranges that might include text' do
      expect(parser.to_years_array('December 1900 - March 1912')).to match_array 1900..1912
    end

    it 'handles combined range and individual date' do
      expect(parser.to_years_array('1832 and 1949-1962')).to match_array [1832, (1949..1962).to_a].flatten
    end

    it 'handles explicitly undated' do
      expect(parser.to_years_array('Undated.')).to eq []
    end
  end

  describe '#parse' do
    context 'when parsing swarthmore ead' do
      let(:xml) { file_fixture('ead/ead1.xml') }

      it 'has expected value for the id suffix' do
        expect(parser.id).to end_with 'SFHL.SC.289'
      end

      it 'has expected values for legacy ids' do
        expect(parser.legacy_ids).to contain_exactly(
          "#{endpoint.slug.upcase}_USPSHSFHLSC289",
          "#{endpoint.slug.upcase}_SFHLSC289USPSH"
        )
      end

      it 'has expected value for title_tsim' do
        expect(parser.title).to eq(
          'Compiled birth, death, marriage records within the area of Philadelphia Yearly Meeting'
        )
      end

      it 'has the right extent (a single value)' do
        expect(parser.extent).to eq ['.02 linear feet (5 folders)']
      end

      it 'has the right value for upenn record flag' do
        expect(parser).not_to be_upenn_record
      end

      it 'has expected years' do
        expect(parser.years).to match_array 1826..1937
      end

      it 'has the right repository address' do
        expect(parser.repository_address).to eql('500 College Avenue, Swarthmore, Pennsylvania 19081')
      end
    end

    context 'when parsing sample Penn Museum EAD' do
      let(:xml) { file_fixture('ead/penn_museum_ead_1.xml') }

      it 'has expected value for the id suffix' do
        expect(parser.id).to end_with 'PU-MU.0040'
      end

      it 'has expected values for legacy ids' do
        expect(parser.legacy_ids[0]).to end_with 'PUMU0040'
      end

      it 'has the right title' do
        expect(parser.title).to eq 'Works Progress Administration Records'
      end

      it 'has the link url' do
        expect(parser.link_url).to eq 'https://www.test.com'
      end

      it 'has the right creator(s)' do
        expect(parser.creators).to eq(
          ['Butler, Mary, 1903-1970', 'Fewkes, Vladimir']
        )
      end

      it 'has expected years' do
        expect(parser.years).to match_array 1935..1943
      end

      it 'has the right unit id' do
        expect(parser.unit_id).to eq 'PU-Mu. 0040'
      end

      it 'has the right pretty unit id' do
        expect(parser.pretty_unit_id).to eq '0040'
      end

      it 'has the right extent (multiple values, properly formatted)' do
        expect(parser.extent).to eq ['2.46 linear feet (7 boxes)', '1.85 gigabytes']
      end

      it 'has the right abstract-scope-contents' do
        expect(parser.abstract_scope_contents).to start_with(
          'During the Great Depression'
        )
      end

      it 'has the right people' do
        expect(parser.people).to eq(
          [
            'Jayne, Horace Howard Furness, 1898-1975', 'Johnson, Eldridge Reeves, b. 1867-d. 1945',
            'Sir Michael Kanning IV, Duke of Snapfinger', 'Vaillant, George C., b.1901-d.1945'
          ]
        )
      end

      it 'has the right subjects with no duplicate values' do
        expect(parser.subjects).to eq(
          [
            'Physical anthropology',
            'WPA Statewide Museum Service'
          ]
        )
      end

      it 'has the right places' do
        expect(parser.places).to eq(
          ['Alaska', 'Guatemala', 'Marsa Matruh (Egypt)', 'Piedras Negras site (Guatemala)']
        )
      end

      it 'has the right occupations' do
        expect(parser.occupations).to eq(['Administrators'])
      end

      it 'has the right corpnames' do
        expect(parser.corp_names).to eq(
          [
            'Fairmount Park Commission (Philadelphia, Pa.).',
            'University of Pennsylvania. Museum of Archaeology and Anthropology.'
          ]
        )
      end

      it 'has the right language(s)' do
        expect(parser.languages).to eq(['English'])
      end

      it 'has the right full repository name' do
        expect(parser.repository).to eq 'University of Pennsylvania: Penn Museum Archives'
      end

      it 'has the right value for upenn record flag' do
        expect(parser).to be_upenn_record
      end

      it 'has the right repository address' do
        expect(parser.repository_address).to eql('3260 South Street, Philadelphia, Pennsylvania, 19104-6324')
      end

      it 'has the right preferred citation' do
        expect(parser.preferred_citation).to eq(
          '[Indicate the cited item or series here], WPA Information, AB 123, Penn Museum.'
        )
      end

      it 'has the right date added' do
        expect(parser.date_added).to eq '2017-03-03'
      end

      it 'has the right display date' do
        expect(parser.display_date).to eq ['1935-1943 (inclusive)', '1940 (bulk)']
      end

      it 'has the right donor(s)' do
        expect(parser.donor).to eq ['Sir Michael Kanning IV, Duke of Snapfinger']
      end

      it 'has the right genre/form(s)' do
        expect(parser.genre_form).to eq ['Photographs']
      end

      it 'has the right name(s)' do
        expect(parser.names).to eq(
          [
            'Butler, Mary, 1903-1970', 'Fewkes, Vladimir',
            'Fairmount Park Commission (Philadelphia, Pa.).',
            'Jayne, Horace Howard Furness, 1898-1975',
            'Johnson, Eldridge Reeves, b. 1867-d. 1945',
            'University of Pennsylvania. Museum of Archaeology and Anthropology.',
            'Sir Michael Kanning IV, Duke of Snapfinger',
            'Vaillant, George C., b.1901-d.1945'
          ]
        )
      end

      it 'returns false for online_content' do
        expect(parser).not_to be_online_content
      end
    end

    context 'when parsing an EAD from ASpace' do
      let(:xml) { file_fixture('ead/upenn_ms_coll_200.xml') }

      it 'gets Creator values from all parts of the document regardless of XML attribute case' do
        expect(parser.creators).to eq(
          ['Anderson, Marian', 'Creator, Another']
        )
      end

      # ensure online content flag is set when digital object info is deeply nested in a <c> node
      it 'returns true for online_content' do
        expect(parser).to be_online_content
      end
    end

    context 'with digital object info in EAD v3 spec' do
      let(:xml) { file_fixture('ead/dao_ead_v3.xml') }

      it 'returns true for online_content' do
        expect(parser).to be_online_content
      end
    end

    context 'with digital object info in EAD v2 spec' do
      let(:xml) { file_fixture('ead/dao_ead_v2.xml') }

      it 'returns true for online_content' do
        expect(parser).to be_online_content
      end
    end
  end
end
