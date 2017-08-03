# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

  devise_scope :user do
    delete 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end

  resources :friends, only: :index do
    member do
      get :follow
    end
  end

  resource  :account
  resources :authorizations, only: [:destroy]

  root to: 'home#index'
end
