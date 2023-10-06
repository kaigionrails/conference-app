require "sidekiq/web"

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  namespace :admin do
    mount Sidekiq::Web => '/sidekiq', constraints: Module.new {
      def self.matches?(request)
        request.session[:user_id].present? && User.find(request.session[:user_id]).organizer?
      end
    }
  end

  root "home#index"

  get "/login", to: "sessions#new"
  get "/auth/:provider/callback", to: "sessions#create"
  get "/logout", to: "sessions#destroy"

  resources :profiles, only: [:index, :new, :create, :edit, :update] do
    resources :profile_images, only: [:destroy]
  end
end
