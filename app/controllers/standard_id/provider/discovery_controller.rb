module StandardId
  module Provider
    class DiscoveryController < BaseController
      def show
        render json: openid_configuration
      end

      private

      def openid_configuration
        issuer = StandardId.config.issuer
        provider_config = StandardId.config.provider

        {
          issuer: issuer,
          authorization_endpoint: "#{issuer}/api/authorize",
          token_endpoint: "#{issuer}/api/oauth/token",
          userinfo_endpoint: "#{issuer}/api/userinfo",
          jwks_uri: "#{issuer}/api/.well-known/jwks.json",
          introspection_endpoint: "#{issuer}/api/provider/introspect",
          revocation_endpoint: "#{issuer}/api/provider/revoke",
          scopes_supported: provider_config.scopes_supported,
          response_types_supported: %w[code token],
          grant_types_supported: %w[authorization_code client_credentials refresh_token],
          subject_types_supported: provider_config.subject_types_supported,
          id_token_signing_alg_values_supported: [StandardId::JwtService.algorithm],
          token_endpoint_auth_methods_supported: %w[client_secret_basic client_secret_post],
          claims_supported: provider_config.claims_supported,
          code_challenge_methods_supported: %w[S256 plain]
        }.compact
      end
    end
  end
end
