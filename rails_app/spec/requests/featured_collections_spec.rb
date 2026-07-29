# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'FeaturedCollections', type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
    allow(RepositoryQueries).to receive(:titles_by_repository).and_return(
      'Test Repo' => ['Valid Title', 'Another Title']
    )
  end

  describe 'GET /admin/featured_collections' do
    it 'returns a successful response' do
      get featured_collections_path
      expect(response).to be_successful
    end

    it 'lists featured collections' do
      create(:featured_collection, title: 'Valid Title', repository: 'Test Repo')
      get featured_collections_path
      expect(response.body).to include('Valid Title')
    end
  end

  describe 'GET /admin/featured_collections/new' do
    it 'renders the new form' do
      get new_featured_collection_path
      expect(response).to be_successful
    end
  end

  describe 'POST /admin/featured_collections' do
    context 'with valid params' do
      it 'creates a featured collection and redirects' do
        expect {
          post featured_collections_path,
               params: { featured_collection: { title: 'Valid Title', repository: 'Test Repo' } }
        }.to change(FeaturedCollection, :count).by(1)
        expect(response).to redirect_to(featured_collections_path)
      end
    end

    context 'with invalid params' do
      it 're-renders the form with unprocessable_entity' do
        post featured_collections_path,
             params: { featured_collection: { title: 'Missing Title', repository: 'Test Repo' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /admin/featured_collections/:id' do
    it 'destroys the featured collection and redirects' do
      fc = create(:featured_collection, title: 'Valid Title', repository: 'Test Repo')
      expect {
        delete featured_collection_path(fc)
      }.to change(FeaturedCollection, :count).by(-1)
      expect(response).to redirect_to(featured_collections_path)
    end
  end
end
