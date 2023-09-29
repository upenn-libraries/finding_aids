# frozen_string_literal: true

require 'rails_helper'

shared_examples_for 'synchronizable' do
  describe '.sync_from_csv' do
    context 'when csv path is invalid' do
      subject(:sync) { described_class.sync_from_csv('random/path.csv') }

      it 'raises error' do
        expect { sync }.to raise_error(%r{Cannot read CSV file at random/path.csv})
      end
    end

    context 'when csv contains invalid headers' do
      let(:csv_file) { file_fixture('endpoint_csv/missing_headers.csv') }

      it 'raises error' do
        expect { described_class.sync_from_csv(csv_file) }.to raise_error 'CSV does not match required headers'
      end
    end

    context 'when csv is empty' do
      let(:csv_file) { file_fixture('endpoint_csv/no_data.csv') }

      it 'raises error' do
        expect { described_class.sync_from_csv(csv_file) }.to raise_error 'CSV does not contain data'
      end
    end

    context 'when endpoint type is invalid' do
      subject(:sync) { described_class.sync_from_csv(csv_file) }

      let(:csv_file) { file_fixture('endpoint_csv/invalid_type.csv') }

      it 'raises error' do
        expect { sync }.to raise_error ActiveRecord::RecordInvalid, /Source type is not included in the list/
      end
    end

    context 'when adding new aspace and index endpoint' do
      let(:csv_file) { file_fixture('endpoint_csv/new_endpoints.csv') }

      before { described_class.sync_from_csv(csv_file) }

      it 'creates upenn_rbml endpoint' do
        expect(Endpoint.find_by(slug: 'upenn_rbml')).to have_attributes(
          public_contacts: ['rbml@pobox.upenn.edu'],
          tech_contacts: ['hmengel@pobox.upenn.edu'],
          source_type: 'penn_archives_space',
          url: 'https://upennstaff.as.atlas-sys.com',
          aspace_id: 4,
        )
      end

      it 'creates haverford endpoint' do
        expect(Endpoint.find_by(slug: 'haverford')).to have_attributes(
          public_contacts: ['hc-special@haverford.edu'],
          tech_contacts: ['shorowitz@haverford.edu'],
          source_type: 'index',
          url: 'https://web.tricolib.brynmawr.edu/paarp/haverford/production/'
        )
      end

      context 'when updating endpoints' do
        let(:update_csv_file) { file_fixture('endpoint_csv/update_endpoints.csv') }

        before { described_class.sync_from_csv(update_csv_file) }

        it 'updates upenn_rbml endpoint' do
          expect(Endpoint.find_by(slug: 'upenn_rbml')).to have_attributes(
            public_contacts: ['rbml@pobox.upenn.edu'],
            tech_contacts: ['hmengel@pobox.upenn.edu'],
            source_type: 'index',
            url: 'http://127.0.0.1:8080/ead/manuscripts'
          )
        end

        it 'updates haverford endpoint' do
          expect(Endpoint.find_by(slug: 'haverford')).to have_attributes(
            public_contacts: ['public@haverford.edu'],
            tech_contacts: ['example@haverford.edu'],
            source_type: 'index',
            url: 'https://web.tricolib.brynmawr.edu/paarp/haverford/production/new'
          )
        end

        it 'adds upenn_cajs endpoint' do
          expect(Endpoint.find_by(slug: 'upenn_cajs')).to have_attributes(
            public_contacts: ['cajs@pobox.upenn.edu'],
            tech_contacts: ['cajs@pobox.upenn.edu'],
            source_type: 'penn_archives_space',
            url: 'https://upennstaff.as.atlas-sys.com',
            aspace_id: 5
          )
        end
      end

      context 'when removing endpoints' do
        let(:remove_csv_file) { file_fixture('endpoint_csv/remove_endpoints.csv') }
        let(:solr) { instance_double(SolrService) }

        before do
          allow(solr).to receive(:delete_by_endpoint).with('haverford')
          described_class.sync_from_csv(remove_csv_file, solr: solr)
        end

        it 'removes haverford' do
          expect(Endpoint.find_by(slug: 'haverford')).to be_nil
        end

        it 'does not delete upenn_rbml' do
          expect(Endpoint.find_by(slug: 'upenn_rbml')).not_to be_nil
        end
      end
    end
  end
end
