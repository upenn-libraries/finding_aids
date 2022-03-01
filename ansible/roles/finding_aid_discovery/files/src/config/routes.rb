# frozen_string_literal: true

Rails.application.routes.draw do
  mount Blacklight::Engine => '/'
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog',
                     controller: 'catalog', constraints: { id: %r{[^/]+} } do
    concerns :searchable
  end
  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog',
                             controller: 'catalog', constraints: { id: %r{[^/]+} } do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  scope :admin do
    resources :endpoints, only: %i[index show]
  end

  get 'repositories', to: 'catalog#repositories'
  root to: 'catalog#index'
end
