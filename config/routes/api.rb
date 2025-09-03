StandardId::ApiEngine.routes.draw do
  scope module: :api do
    resource :authorize, only: [:show], controller: :authorization

    namespace :oauth do
      resource :token, only: [:create]

      namespace :callback do
        get :google, to: "providers#google"
        post :apple, to: "providers#apple"
      end
    end
  end
end
