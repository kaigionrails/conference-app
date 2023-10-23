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

  # For PWA
  get "/sw.js", to: "pwa#service_worker", as: "service_worker"
  get "/manifest.json", to: "pwa#manifest", as: "pwa_manifest"

  post "/webpush_subscription", to: "webpush_subscription#create"
  post "/sample_webpush_notifications", to: "sample_webpush_notifications#create"

  resources :profiles, only: [:index, :new, :create, :edit, :update] do
    resources :profile_images, only: [:destroy]
  end

  resources :talk_bookmarks, only: [:create, :destroy]
  resources :unread_announcements, only: [:destroy]

  get "/about", to: "about#index"

  namespace :admin do
    resources :users, only: [:index, :show, :edit, :update]
    resources :talks, only: [:index, :show, :edit, :update]
    resources :announcements, only: [:index, :new, :create, :show, :edit, :update]
  end
  get "/admin", to: "admin#index"

  scope "/:event_slug", as: "event" do
    get "/", to: "events#show"
    resources :talks, only: [:index, :show]
    resources :announcements, only: [:index, :show]
  end
end
