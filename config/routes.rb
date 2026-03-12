StandardId::Provider::Engine.routes.draw do
  scope ".well-known" do
    get "openid-configuration", to: "discovery#show"
  end

  scope "api/provider" do
    post "introspect", to: "introspection#create"
    post "revoke", to: "revocation#create"
    resource :consent, only: [ :show, :create, :destroy ], controller: :consent
  end
end
