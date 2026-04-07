Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks", registrations: "users/registrations" }
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

  # 静的ページ
  get "terms", to: "pages#terms"
  get "privacy", to: "pages#privacy"

  # お問い合わせ
  resources :contacts, only: %i[new create]

  get "/share/:token", to: "shares#show", as: :share

  get "/rooms/:room_id/members/:id", to: "rooms/members#show", as: :room_member

  namespace :my do
    # 自分用（単数）
    resource :profile, only: %i[new create edit update destroy]
  end

  namespace :mypage do
    root to: "dashboards#show"
    resource :dashboard, only: [ :update ]
    resources :rooms, only: %i[index create edit update destroy] do
      member do
        patch :lock
        patch :unlock
        patch :regenerate_share_link
      end
    end
    resources :room_memberships, only: [ :destroy ]
  end

  devise_scope :user do
    get "mypage/settings", to: "users/registrations#edit", as: :mypage_settings
    patch "mypage/settings", to: "users/registrations#update"
  end

  namespace :admin do
    root "dashboards#show"
  end
end
