Rails.application.routes.draw do
  mount StandardId::WebEngine => "/"

  get "info", to: "public#info"

  namespace :backend do
    root to: "dashboard#index"
  end

  namespace :api do
    mount StandardId::ApiEngine => "/"

    resource :ping, only: [:show]
  end
end
