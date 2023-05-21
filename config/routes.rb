Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  root "home#index"

  get "/login", to: "sessions#new"
  get "/auth/:provider/callback", to: "sessions#create"
  get "/logout", to: "sessions#destroy"

  resources :profiles, only: [:index, :new, :create, :edit, :update]
end
