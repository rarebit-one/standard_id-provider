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

      # Controllers are reloadable, so this cannot live in the initializer
      # above: referencing the constant there would pin the boot-time class and
      # every `reload!` in development would drop the extension. `to_prepare`
      # runs on each reload, and `prepend` of an already-prepended module is a
      # no-op, so re-running it is free.
      config.to_prepare do
        StandardId::Api::Oauth::IntrospectionsController.prepend(
          StandardId::Provider::Extensions::IntrospectionsControllerExt
        )
      end
    end
  end
end
