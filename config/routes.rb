Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
  get "home/index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")

  # トップページ
  root "home#index"

  # 他人用（複数）
  resources :profiles, only: %i[index show]

  resources :hobbies, only: [] do
    collection do
      get :autocomplete
    end
  end

  get "/share/:token", to: "shares#show", as: :share

  get "/rooms/:room_id/members/:id", to: "rooms/members#show", as: :room_member

  namespace :my do
    # 自分用（単数）
    resource :profile, only: %i[new create edit update destroy]
    resources :rooms, only: %i[index create update edit destroy]
  end

  namespace :mypage do
    root to: "dashboards#show"
    resource :dashboard, only: [ :update ]
    resources :rooms, only: %i[index create edit update destroy]
  end

  devise_scope :user do
    get "mypage/settings", to: "users/registrations#edit", as: :mypage_settings
    patch "mypage/settings", to: "users/registrations#update"
  end
end
