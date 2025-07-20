Rails.application.routes.draw do
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # Root route
  root "home#index"

  # Auth0 authentication routes (OmniAuth handles these automatically)
  # The middleware will handle /auth/auth0 POST requests
  get "/auth/auth0/callback" => "auth0#callback"
  get "/auth/failure" => "auth0#failure"
  get "/logout" => "auth0#logout"

  # Sidekiq web interface (authenticated users only)
  require "sidekiq/web"
  require "sidekiq/cron/web"

  # Authentication constraint for Sidekiq
  class SidekiqConstraint
    def self.matches?(request)
      request.session[:user_id].present?
    end
  end

  mount Sidekiq::Web => "/sidekiq", constraints: SidekiqConstraint

  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication
      get "me", to: "auth#me"

      # Wallets
      resources :wallets, only: [ :index, :create, :show ] do
        member do
          # Remove balance endpoint - not needed anymore
          # get :balance
          post :sign_message
          post :send_transaction
        end
      end

      # Transactions
      resources :transactions, only: [ :index, :show ]
    end
  end

  # Frontend routes (catch-all for SPA)
  get "/dashboard", to: "home#dashboard"
  get "/login", to: "home#login"
  # Redirect to index all weird possible paths
  get "*path", to: "home#index", constraints: ->(request) do
    !request.xhr? && request.format.html?
  end
end
