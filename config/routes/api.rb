StandardId::ApiEngine.routes.draw do
  scope module: :api do
    resource :authorize, only: [:show], controller: :authorization

    namespace :oauth do
      resource :token, only: [:create]
    end
  end
end
