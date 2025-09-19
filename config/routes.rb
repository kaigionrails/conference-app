Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  namespace :admin do
    mount MissionControl::Jobs::Engine, at: "/jobs", constraints: Module.new {
      def self.matches?(request)
        request.session[:user_id].present? && User.find(request.session[:user_id]).organizer?
      end
    }
  end

  root "home#index"

  get "/login", to: "sessions#new"
  get "/auth/:provider/callback", to: "auth_callback#create"
  post "/auth/:provider", to: "sessions#create"
  get "/logout", to: "sessions#destroy"

  # For PWA
  get "/sw.js", to: "pwa#service_worker", as: "service_worker"
  get "/manifest.json", to: "pwa#manifest", as: "pwa_manifest"
  get "/setting", to: "setting#index"

  post "/webpush_subscription", to: "webpush_subscription#create"
  post "/sample_webpush_notifications", to: "sample_webpush_notifications#create"

  resources :profiles, only: [:index, :new, :create, :edit, :update] do
    resources :profile_images, only: [:destroy]
  end
  resources :profile_badges, only: [:new, :create]
  post "/locale_settings", to: "locale_settings#update", as: :locale_setting

  get "/@:username", to: "users#show", as: :user

  resources :talk_bookmarks, only: [:create, :destroy]
  resources :unread_announcements, only: [:destroy]

  get "/about", to: "about#index"

  get "/live/:id", to: "live_streams#show", as: "live_stream"

  resources :signages, only: [:index]
  resources :signage_devices, only: [:index]

  namespace :admin do
    resources :events, only: [:index, :show, :new, :create, :edit, :update]
    resources :ongoing_events, only: [:create, :update]
    resources :users, only: [:index, :show, :new, :create, :edit, :update]
    resources :profiles, only: [:show] do
      resources :profile_badges_profiles, only: [:new, :create]
    end
    resources :talks, only: [:index, :show, :edit, :update]
    resources :tito_tickets, only: [:index, :show]
    resources :announcements, only: [:index, :new, :create, :show, :edit, :update]
    resources :profile_badges, only: [:index, :new, :create, :edit, :update, :destroy]
    resources :live_streams, only: [:index, :new, :create, :update]
    resources :signages, only: [:index, :new, :create, :update]
    resources :signage_schedules, only: [:new, :create, :edit, :update, :destroy]
    resources :signage_schedule_assigns, only: [:new, :create, :destroy]
    resources :signage_panels, only: [:new, :create, :edit, :update]
    resources :signage_devices, only: [:new, :create, :edit, :update]
    resources :signage_device_assigns, only: [:new, :create, :update, :destroy]
    resources :signage_pages, only: [:index, :new, :create, :edit, :update, :destroy]
  end

  get "/admin", to: "admin#index"
  resources :operators, only: [:index]

  get "/up" => "rails/health#show", :as => :rails_health_check

  scope "/:event_slug", as: "event" do
    get "/", to: "events#show"
    resources :talks, only: [:index, :show]
    resources :announcements, only: [:index, :show]
  end
end
