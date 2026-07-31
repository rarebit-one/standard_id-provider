module StandardId
  module Provider
    # OpenID Connect Discovery (`GET /.well-known/openid-configuration`).
    #
    # ## Why this no longer builds the document by hand
    #
    # It used to interpolate every endpoint off the issuer with a hardcoded
    # `/api` segment:
    #
    #     authorization_endpoint: "#{issuer}/api/authorize"
    #
    # That is the same defect core fixed in standard_id 0.33.0. It is wrong two
    # ways at once: it assumes ApiEngine is mounted at exactly `/api`, and it
    # conflates the ISSUER with the ENDPOINT BASE. Those are different things —
    # the issuer is a stable security identifier (RFC 8414 §2) that clients
    # match byte-for-byte against their discovery URL and against the `iss`
    # claim, while the endpoint base is merely where the endpoints happen to
    # live. An app whose issuer does not carry the mount path got a document
    # advertising URLs that 404.
    #
    # Resolution is now core's: StandardId::Oauth::DiscoveryResolver reads
    # `config.oauth.discovery_endpoint_base` and
    # `config.oauth.discovery_metadata_overrides`, and the document itself is
    # built by StandardId::Oauth::DiscoveryDocument, so this document cannot
    # drift from the two core serves.
    #
    # ## Setting `discovery_endpoint_base` is not optional for this engine
    #
    # Core's own well-known controllers can derive the base from the request,
    # because they are served from INSIDE the ApiEngine mount, where
    # `request.script_name` IS the mount path. This controller is served from
    # the PROVIDER engine's mount, which is a different mount (typically `/`).
    # `:request` would therefore resolve to the origin root and advertise
    # `<origin>/oauth/token` for an ApiEngine mounted at `/api`.
    #
    # So a host serving this document must say where ApiEngine actually is:
    #
    #     c.oauth.discovery_endpoint_base = ->(request:) { "#{request.base_url}/api" }
    #     # or, for a fixed deployment:
    #     c.oauth.discovery_endpoint_base = "https://auth.example.com/api"
    #
    # That is the hardcoded `/api` moving out of gem code and into host config,
    # which is the point.
    class DiscoveryController < ApplicationController
      def show
        resolved = StandardId::Oauth::DiscoveryResolver.resolve(request: request)

        if resolved[:issuer].blank?
          render json: { error: "Issuer not configured" }, status: :not_found
          return
        end

        response.headers["Cache-Control"] = "public, max-age=3600"
        render json: openid_configuration(resolved)
      end

      private

      def openid_configuration(resolved)
        doc = StandardId::Oauth::DiscoveryDocument.build(
          resolved[:issuer],
          endpoint_base: resolved[:endpoint_base],
          registration_enabled: StandardId.config.oauth.dynamic_registration_enabled,
          introspection_enabled: StandardId.config.oauth.introspection_enabled
        )

        doc.merge!(provider_members)

        # Host overrides are applied LAST so they win over the provider members
        # too, matching how core's controllers treat them.
        StandardId::Oauth::DiscoveryDocument.apply_overrides!(doc, resolved[:overrides])
      end

      # Only the OIDC IdP members core has no opinion on.
      #
      # Deliberately NOT re-stated here, though the old hand-built document did:
      #
      #   * `response_types_supported: %w[code token]` — this engine extends the
      #     authorization-code flows only. Advertising the implicit flow's
      #     `token` promised something nothing implements.
      #   * `code_challenge_methods_supported: %w[S256 plain]` — core enforces
      #     PKCE with S256 and does not accept `plain`. Advertising it invites a
      #     downgrade attempt that is then rejected.
      #   * `id_token_signing_alg_values_supported` — core derives it from
      #     `config.oauth.signing_algorithm`, which is the same value.
      #
      # `revocation_endpoint` IS replaced: core advertises its own
      # `/oauth/revoke`, but THIS engine's revoke action is the one that writes
      # the StandardId::Provider::RevokedToken denylist that introspection then
      # consults. Built from the engine's own route helper so it follows the
      # mount rather than hardcoding a prefix.
      def provider_members
        provider_config = StandardId.config.provider

        {
          revocation_endpoint: standard_id_provider.revoke_url(
            host: request.host_with_port, protocol: request.protocol
          ),
          scopes_supported: provider_config.scopes_supported,
          subject_types_supported: provider_config.subject_types_supported,
          claims_supported: provider_config.claims_supported
        }
      end
    end
  end
end
