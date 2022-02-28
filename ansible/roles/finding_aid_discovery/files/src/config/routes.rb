# frozen_string_literal: true

Rails.application.routes.draw do
  mount Blacklight::Engine => '/'
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog',
                     controller: 'catalog', constraints: { id: %r{[^/]+} } do
    concerns :searchable
  end

  resources :solr_documents, only: [:show], path: '/catalog',
                             controller: 'catalog', constraints: { id: %r{[^/]+} }

  scope :admin do
    resources :endpoints, only: %i[index show]
  end

  root to: 'catalog#index'
end
