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
        expect(
          hash[:title_tsim]
        ).to eq 'Compiled birth, death, marriage records within the area of Philadelphia Yearly Meeting'
      end
    end

    context 'when parsing sample Penn Museum EAD' do
      let(:url) { "#{endpoint.url}ead/penn_museum_ead_1.xml" }
      let(:xml) { file_fixture('ead/penn_museum_ead_1.xml') }

      it 'has the right title' do
        expect(hash[:title_tsim]).to eq 'Works Progress Administration Records'
      end

      it 'has the right email(s)' do
        expect(hash[:contact_emails_ssm]).to eq endpoint.public_contacts
      end

      it 'has the right creator(s)' do
        expect(hash[:creators_ssim]).to eq(['Butler, Mary, 1903-1970', 'Fewkes, Vladimir'])
      end

      it 'has the right unit id' do
        expect(hash[:unit_id_ssi]).to eq 'PU-Mu. 0040'
      end

      it 'has the right extent' do
        expect(hash[:extent_ssi]).to eq '2.5 Linear feet'
      end

      it 'has the right inclusive date' do
        expect(hash[:inclusive_date_ss]).to eq '1935-1943'
      end

      it 'has the right abstract-scope-contents' do
        expect(hash[:abstract_scope_contents_tsi]).to start_with 'During the Great Depression'
      end

      it 'has the right people' do
        expect(hash[:people_ssim]).to eq([
         'Jayne, Horace Howard Furness, 1898-1975',
         'Johnson, Eldridge Reeves, b. 1867-d. 1945',
         'Sir Michael Kanning IV, Duke of Snapfinger',
         'Vaillant, George C., b.1901-d.1945'
        ])
      end

      it 'has the right subjects' do
        expect(hash[:subjects_ssim]).to eq([
                                             'Physical anthropology',
                                             'WPA Statewide Museum Service'
                                           ])
      end

      it 'has the right places' do
        expect(
          hash[:places_ssim]
        ).to eq(['Alaska', 'Guatemala', 'Marsa Matruh (Egypt)', 'Piedras Negras site (Guatemala)'])
      end

      it 'has the right corpnames' do
        expect(hash[:corpnames_ssim]).to eq([
          'Fairmount Park Commission (Philadelphia, Pa.).',
          'University of Pennsylvania. Museum of Archaeology and Anthropology.'
        ])
      end

      it 'has the right language(s)' do
        expect(hash[:languages_ssim]).to eq(['English'])
      end

      it 'has the right full repository name' do
        expect(hash[:repository_ssi]).to eq 'University of Pennsylvania: Penn Museum Archives'
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

      it 'has the right preferred citation' do
        expect(hash[:preferred_citation_ss]).to eq(
          '[Indicate the cited item or series here], WPA Information, AB 123, Penn Museum.'
        )
      end

      it 'has the right date added' do
        expect(hash[:date_added_ssi]).to eq '2017-03-03'
      end

      it 'has the right donor(s)' do
        expect(hash[:donors_ssim]).to eq ['Sir Michael Kanning IV, Duke of Snapfinger']
      end

      it 'has the right name(s)' do
        expect(hash[:names_ssim]).to eq [
          'Butler, Mary, 1903-1970',
          'Fewkes, Vladimir',
          'Fairmount Park Commission (Philadelphia, Pa.).',
          'Jayne, Horace Howard Furness, 1898-1975',
          'Johnson, Eldridge Reeves, b. 1867-d. 1945',
          'University of Pennsylvania. Museum of Archaeology and Anthropology.',
          'Sir Michael Kanning IV, Duke of Snapfinger',
          'Vaillant, George C., b.1901-d.1945'
          ]

      end
    end
  end
end
