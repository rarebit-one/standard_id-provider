Rails.application.routes.draw do
  mount StandardId::Provider::Engine => "/"

  mount StandardId::WebEngine => "/", as: :standard_id_web

  scope "api" do
    mount StandardId::ApiEngine => "/", as: :standard_id_api
  end
end
