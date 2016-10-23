Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

  resources :friends, only: :index do
    member do
      get :follow
    end
  end

  root to: 'home#index'
end
