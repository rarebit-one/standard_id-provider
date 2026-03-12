Rails.application.routes.draw do
  mount StandardId::Provider::Engine => "/standard_id-provider"
end
