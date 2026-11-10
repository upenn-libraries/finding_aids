# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'FeaturedCollections', type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  context 'with an existing record' do
    let(:fc) { create :featured_collection }
    let(:lookup_response) do
      { title: fc.title, repository: fc.repository }
    end

    before do
      allow(RepositoryQueries).to receive(:featured_collection_data_for).and_return(lookup_response)
    end

    describe 'GET /admin/featured_collections' do
      it 'returns a successful response' do
        get featured_collections_path
        expect(response).to be_successful
      end

      it 'lists featured collections' do
        get featured_collections_path
        expect(response.body).to include(fc.record_id)
      end
    end

    describe 'GET /admin/featured_collections/new' do
      it 'renders the new form' do
        get new_featured_collection_path
        expect(response).to be_successful
      end
    end

    describe 'DELETE /admin/featured_collections/:id' do
      it 'destroys the featured collection and redirects' do
        expect {
          delete featured_collection_path(fc)
        }.to change(FeaturedCollection, :count).by(-1)
        expect(response).to redirect_to(featured_collections_path)
      end
    end
  end

  context 'when creating and removing records' do
    let(:fc) { build :featured_collection }
    let(:lookup_response) do
      { title: fc.title, repository: fc.repository }
    end

    before do
      allow(RepositoryQueries).to receive(:featured_collection_data_for).and_return(lookup_response)
    end

    describe 'POST /admin/featured_collections' do
      it 'creates a featured collection and redirects' do
        expect {
          post featured_collections_path,
               params: { featured_collection: { record_id: fc.record_id } }
        }.to change(FeaturedCollection, :count).by(1)
        expect(response).to redirect_to(featured_collections_path)
      end

      context 'with a record that does not exist' do
        let(:lookup_response) { nil }

        it 're-renders the form with unprocessable_content' do
          post featured_collections_path,
               params: { featured_collection: { record_id: 'NOPE9999' } }
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context 'with failed model validation' do
        it 're-renders the form with unprocessable_content' do
          fc.save!
          post featured_collections_path,
               params: { featured_collection: { record_id: fc.record_id } }
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end
end
