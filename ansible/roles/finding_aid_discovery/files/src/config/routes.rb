# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  devise_scope :user do
    post 'sign_out', to: 'devise/sessions#destroy', as: 'destroy_user_session'
  end
  get 'login', to: 'login#index'
  get 'admin', to: 'admin#index', as: 'admin'
  authenticated do
    root to: 'catalog#index', as: 'authenticated_root'
  end

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
  get 'about', to: 'static_pages#about'
  get 'how-to-use', to: 'static_pages#how_to_use'

  root to: 'catalog#index'
end
