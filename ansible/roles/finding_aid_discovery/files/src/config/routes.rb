# frozen_string_literal: true

Rails.application.routes.draw do
  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  mount Blacklight::Engine => '/'
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/records',
                     controller: 'catalog', constraints: { id: %r{[^/]+} } do
    concerns :searchable
    concerns :range_searchable
  end

  # Legacy ID lookup route
  get '/records/legacy/:id', to: 'legacy#redirect'

  resources :solr_documents, only: [:show], path: '/records',
                             controller: 'catalog', constraints: { id: %r{[^/]+} }

  resources :requests, only: %i[create] do
    collection do
      post 'prepare'
    end
  end

  scope :admin do
    resources :endpoints, only: %i[index show]
  end

  get 'repositories', to: 'catalog#repositories'
  get 'login', to: 'login#index'
  root to: 'catalog#index'
end
