StandardId::ApiEngine.routes.draw do
  namespace :oauth do
    resource :token, only: [:create]
  end
end
