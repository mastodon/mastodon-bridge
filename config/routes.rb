Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

  resources :friends, only: :index do
    member do
      post :follow
    end
  end

  root to: 'home#index'
end
