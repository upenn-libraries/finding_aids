# frozen_string_literal: true

require 'rails_helper'

describe EadParser do
  let(:endpoint) { build :endpoint, :index_harvest }
  let(:parser) { described_class.new endpoint }
 
  describe '#parse' do
    let(:hash) { parser.parse(url, xml) }

    context 'when parsing swarthmore ead' do
      let(:xml) { file_fixture('ead/ead1.xml') }
      let(:url) { "#{endpoint.url}ead/ead1.xml" }

      it 'returns a hash' do
        expect(hash).to be_a_kind_of Hash
      end

      it 'has expected value for the id suffix' do
        expect(hash[:id]).to end_with '_ead1'
      end

      it 'has expected value for title_tsim' do
        expect(hash[:title_tsim]).to eq 'Compiled birth, death, marriage records within the area of Philadelphia Yearly Meeting'
      end
    end

    context 'when parsing sample Penn Museum EAD' do
      let(:url) { "#{endpoint.url}ead/penn_museum_ead_1.xml" }
      let(:xml) { file_fixture('ead/penn_museum_ead_1.xml') }

      it 'has the right title' do
        expect(hash[:title_tsim]).to eq 'Works Progress Administration Records'
      end

      it 'has the right email' do
        expect(hash[:contact_emails_ssm]).to eq endpoint.public_contacts
      end

      it 'has the right creator' do
        expect(hash[:creator_ssim]).to eq ['Butler, Mary, 1903-1970',
                                           'Fewkes, Vladimir']
      end

      it 'has the right unit id' do
        expect(hash[:unit_id_ssi]).to eq 'PU-Mu. 0040'
      end

      it 'has the right extent' do
        expect(hash[:extent_ssim]).to eq ['2.5 Linear feet']
      end

      it 'has the right inclusive date' do
        expect(hash[:inclusive_date_ss]).to eq '1935-1943'
      end

      it 'has the right abstract-scope-contents' do
        expect(hash[:abstract_scope_contents_tsi]).to start_with 'During the Great Depression'
      end

      it 'has the right people' do
        expect(hash[:people_ssim]).to eq [
                                           'Jayne, Horace Howard Furness, 1898-1975',
                                           'Johnson, Eldridge Reeves, b. 1867-d. 1945',
                                           'Vaillant, George C., b.1901-d.1945'
                                         ]
      end

      it 'has the right subjects' do
        expect(hash[:subjects_ssim]).to eq [
                                             'Physical anthropology',
                                             'WPA Statewide Museum Service'
                                           ]
      end
      
      it 'has the right places' do
        expect(hash[:places_ssim]).to eq [
                                           'Alaska',
                                           'Guatemala',
                                           'Marsa Matruh (Egypt)',
                                           'Piedras Negras site (Guatemala)'
                                         ]
      end
      
      it 'has the right corpnames' do
        expect(hash[:corpnames_ssim]).to eq [
                                              'Fairmount Park Commission (Philadelphia, Pa.).',
                                              'University of Pennsylvania. Museum of Archaeology and Anthropology.'
                                            ]

      end
    end
  end
end
