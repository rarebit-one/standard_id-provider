module StandardId
  module Provider
    class Engine < ::Rails::Engine
      isolate_namespace StandardId::Provider

      initializer "standard_id_provider.extend_core" do
        StandardId::Oauth::TokenGrantFlow.prepend(
          StandardId::Provider::Extensions::TokenGrantFlowExt
        )
        StandardId::Oauth::AuthorizationCodeAuthorizationFlow.prepend(
          StandardId::Provider::Extensions::AuthorizationFlowExt
        )
        StandardId::Oauth::Subflows::TraditionalCodeGrant.prepend(
          StandardId::Provider::Extensions::TraditionalCodeGrantExt
        )
        StandardId::Oauth::AuthorizationCodeFlow.prepend(
          StandardId::Provider::Extensions::AuthorizationCodeFlowExt
        )
      end
    end
  end
end
