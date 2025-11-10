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
end
