# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  devise_scope :user do
    get 'login', to: 'login#index', as: :new_user_session
    post 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end

  # adds in a login_path route helper
  get 'login', to: 'login#index', as: :login

  scope :admin do
    get '/', to: 'admin#index', as: :admin
    resources :users
  end

  mount Blacklight::Engine => '/'
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/records',
                     controller: 'catalog', constraints: { id: %r{[^/]+} } do
    concerns :searchable
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

  scope :status do
    get '/', to: 'status#index', as: :endpoints_status
    get '/:id', to: 'status#show', as: :endpoint_status
  end

  get 'repositories', to: 'catalog#repositories'
  get 'about', to: 'static_pages#about'
  get 'how-to-use', to: 'static_pages#how_to_use'

  root to: 'catalog#index'
end
