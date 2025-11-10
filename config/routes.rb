Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  scope :auth do
    post "/register", to: "auth#register"
    post "/login", to: "auth#login"
    post "/logout", to: "auth#logout"
    post "/refresh", to: "auth#refresh"
    get "/me", to: "auth#me"
  end

  resources :conversations, only: %i[index show create] do
    resources :messages, only: :index
  end

  resources :messages, only: :create

  scope :expert do
    get "/profile", to: "expert_profiles#show"
    put "/profile", to: "expert_profiles#update"

    get "/queue", to: "expert#queue"
    post "/conversations/:conversation_id/claim", to: "expert#claim"
    post "/conversations/:conversation_id/unclaim", to: "expert#unclaim"
    get "/assignments/history", to: "expert#history"
  end

  namespace :api do
    get "/conversations/updates", to: "conversations#updates"
    get "/messages/updates", to: "messages#updates"
    get "/expert-queue/updates", to: "expert_queue#updates"
  end

  get "/health", to: "health#show"
end
