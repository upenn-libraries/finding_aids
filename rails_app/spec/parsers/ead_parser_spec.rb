# frozen_string_literal: true

require 'rails_helper'

describe EadParser do
  let(:endpoint) { build(:endpoint, :webpage_harvest) }
  let(:parser) { described_class.new endpoint }

  describe '#to_years_array' do
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
    let(:hash) { parser.parse(xml) }

    context 'when parsing swarthmore ead' do
      let(:xml) { file_fixture('ead/ead1.xml') }

      it 'returns a hash' do
        expect(hash).to be_a Hash
      end

      it 'has expected value for the id suffix' do
        expect(hash[:id]).to end_with 'SFHL.SC.289'
      end

      it 'has expected values for legacy ids' do
        expect(hash[:legacy_ids_ssim]).to contain_exactly(
          "#{endpoint.slug.upcase}_USPSHSFHLSC289",
          "#{endpoint.slug.upcase}_SFHLSC289USPSH"
        )
      end

      it 'has expected value for title_tsim' do
        expect(hash[:title_tsi]).to eq(
          'Compiled birth, death, marriage records within the area of Philadelphia Yearly Meeting'
        )
      end

      it 'has the right extent (a single value)' do
        expect(hash[:extent_ssim]).to eq ['.02 linear feet (5 folders)']
      end

      it 'has the right value for upenn record flag' do
        expect(hash[:upenn_record_bsi]).to eql 'F'
      end

      it 'has expected years' do
        expect(hash[:years_iim]).to match_array 1826..1937
      end

      it 'has the right repository address' do
        expect(hash[:repository_address_ssi]).to eql('500 College Avenue, Swarthmore, Pennsylvania 19081')
      end
    end

    context 'when parsing sample Penn Museum EAD' do
      let(:xml) { file_fixture('ead/penn_museum_ead_1.xml') }

      it 'has expected value for the id suffix' do
        expect(hash[:id]).to end_with 'PU-MU.0040'
      end

      it 'has expected values for legacy ids' do
        expect(hash[:legacy_ids_ssim][0]).to end_with 'PUMU0040'
      end

      it 'has the right title' do
        expect(hash[:title_tsi]).to eq 'Works Progress Administration Records'
      end

      it 'has the link url' do
        expect(hash[:link_url_ss]).to eq 'https://www.test.com'
      end

      it 'has the right email(s)' do
        expect(hash[:contact_emails_ssm]).to eq endpoint.public_contacts
      end

      it 'has the right creator(s)' do
        expect(hash[:creators_ssim]).to eq(
          ['Butler, Mary, 1903-1970', 'Fewkes, Vladimir']
        )
      end

      it 'has expected years' do
        expect(hash[:years_iim]).to match_array 1935..1943
      end

      it 'has the right unit id' do
        expect(hash[:unit_id_tsi]).to eq 'PU-Mu. 0040'
      end

      it 'has the right pretty unit id' do
        expect(hash[:pretty_unit_id_ss]).to eq '0040'
      end

      it 'has the right extent (multiple values, properly formatted)' do
        expect(hash[:extent_ssim]).to eq ['2.46 linear feet (7 boxes)', '1.85 gigabytes']
      end

      it 'has the right abstract-scope-contents' do
        expect(hash[:abstract_scope_contents_tsi]).to start_with(
          'During the Great Depression'
        )
      end

      it 'has the right people' do
        expect(hash[:people_ssim]).to eq(
          [
            'Jayne, Horace Howard Furness, 1898-1975', 'Johnson, Eldridge Reeves, b. 1867-d. 1945',
            'Sir Michael Kanning IV, Duke of Snapfinger', 'Vaillant, George C., b.1901-d.1945'
          ]
        )
      end

      it 'has the right subjects with no duplicate values' do
        expect(hash[:subjects_ssim]).to eq(
          [
            'Physical anthropology',
            'WPA Statewide Museum Service'
          ]
        )
      end

      it 'has the right places' do
        expect(hash[:places_ssim]).to eq(
          ['Alaska', 'Guatemala', 'Marsa Matruh (Egypt)', 'Piedras Negras site (Guatemala)']
        )
      end

      it 'has the right occupations' do
        expect(hash[:occupations_ssim]).to eq(['Administrators'])
      end

      it 'has the right corpnames' do
        expect(hash[:corpnames_ssim]).to eq(
          [
            'Fairmount Park Commission (Philadelphia, Pa.).',
            'University of Pennsylvania. Museum of Archaeology and Anthropology.'
          ]
        )
      end

      it 'has the right language(s)' do
        expect(hash[:languages_ssim]).to eq(['English'])
      end

      it 'has the right full repository name' do
        expect(hash[:repository_ssi]).to eq 'University of Pennsylvania: Penn Museum Archives'
      end

      it 'has the right value for upenn record flag' do
        expect(hash[:upenn_record_bsi]).to eql 'T'
      end

      it 'has the right repository name component 1' do
        expect(hash[:repository_name_component_1_ssi]).to eq 'University of Pennsylvania'
      end

      it 'has the right repository name component 2' do
        expect(hash[:repository_name_component_2_ssi]).to eq 'Penn Museum Archives'
      end

      it 'has the right repository name component 3' do
        expect(hash[:repository_name_component_3_ssi]).to be_nil
      end

      it 'has the right repository address' do
        expect(hash[:repository_address_ssi]).to eql('3260 South Street, Philadelphia, Pennsylvania, 19104-6324')
      end

      it 'has the right preferred citation' do
        expect(hash[:preferred_citation_ss]).to eq(
          '[Indicate the cited item or series here], WPA Information, AB 123, Penn Museum.'
        )
      end

      it 'has the right date added' do
        expect(hash[:date_added_ss]).to eq '2017-03-03'
      end

      it 'has the right display date' do
        expect(hash[:display_date_ssim]).to eq ['1935-1943 (inclusive)', '1940 (bulk)']
      end

      it 'has the right donor(s)' do
        expect(hash[:donors_ssim]).to eq ['Sir Michael Kanning IV, Duke of Snapfinger']
      end

      it 'has the right genre/form(s)' do
        expect(hash[:genre_form_ssim]).to eq ['Photographs']
      end

      it 'has the right name(s)' do
        expect(hash[:names_ssim]).to eq(
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

      it 'has a online_content_bsi of "F"' do
        expect(hash[:online_content_bsi]).to eq 'F'
      end
    end

    context 'when parsing an EAD from ASpace' do
      let(:xml) { file_fixture('ead/upenn_ms_coll_200.xml') }

      it 'gets Creator values from all parts of the document regardless of XML attribute case' do
        expect(hash[:creators_ssim]).to eq(
          ['Anderson, Marian', 'Creator, Another']
        )
      end

      # ensure online content flag is set when digital object info is deeply nested in a <c> node
      it 'has an online_content_bsi of "T"' do
        expect(hash[:online_content_bsi]).to eq 'T'
      end
    end

    context 'with digital object info in EAD v3 spec' do
      let(:xml) { file_fixture('ead/dao_ead_v3.xml') }

      it 'has a online_content_bsi of "T"' do
        expect(hash[:online_content_bsi]).to eq 'T'
      end
    end

    context 'with digital object info in EAD v2 spec' do
      let(:xml) { file_fixture('ead/dao_ead_v2.xml') }

      it 'has a online_content_bsi of "T"' do
        expect(hash[:online_content_bsi]).to eq 'T'
      end
    end
  end
end
