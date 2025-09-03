Rails.application.routes.draw do
  mount StandardId::WebEngine => "/", as: :standard_id_web

  get "info", to: "public#info"

  namespace :backend do
    root to: "dashboard#show"
  end

  namespace :api do
    mount StandardId::ApiEngine => "/", as: :standard_id_api

    resource :ping, only: [:show]
  end

  namespace :util do
    post "/session", to: "session#set"
  end

  get "/test_api", to: "test_api#show"
end
