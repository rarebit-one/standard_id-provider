StandardId::ApiEngine.routes.draw do
  scope module: :api do
    namespace :oauth do
      resource :token, only: [:create]
    end
  end
end
