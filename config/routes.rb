StandardId::Provider::Engine.routes.draw do
  scope ".well-known" do
    get "openid-configuration", to: "discovery#show", as: :openid_configuration
  end

  scope "api/provider" do
    # NOTE: there is deliberately no `introspect` route here any more. Core's
    # RFC 7662 endpoint (POST /oauth/introspect, gated on
    # `config.oauth.introspection_enabled`) is the one endpoint, and this engine
    # contributes its denylist into it — see
    # StandardId::Provider::Extensions::IntrospectionsControllerExt.
    post "revoke", to: "revocation#create", as: :revoke
    resource :consent, only: [ :show, :create, :destroy ], controller: :consent
  end
end
