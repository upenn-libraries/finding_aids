# frozen_string_literal: true

Rails.application.routes.draw do
  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  mount Blacklight::Engine => '/'
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog',
                     controller: 'catalog', constraints: { id: %r{[^/]+} } do
    concerns :searchable
    concerns :range_searchable
  end

  resources :solr_documents, only: [:show], path: '/catalog',
                             controller: 'catalog', constraints: { id: %r{[^/]+} }

  resources :requests, only: %i[new] do
    collection do
      post 'prepare'
    end
  end

  scope :admin do
    resources :endpoints, only: %i[index show]
  end

  get 'repositories', to: 'catalog#repositories'
  root to: 'catalog#index'
end
