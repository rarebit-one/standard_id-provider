module StandardId
  module Provider
    module Extensions
      # Teaches core's RFC 7662 endpoint (`POST /oauth/introspect`,
      # StandardId::Api::Oauth::IntrospectionsController) about this engine's
      # access-token denylist.
      #
      # ## Why this replaced a second introspection endpoint
      #
      # This gem used to ship its own `POST /api/provider/introspect`. Since
      # standard_id 0.33.0 core has one too, and core's is strictly more
      # RFC-conformant:
      #
      #   * RFC 7662 §2.2 — every failure mode renders `{"active": false}` and
      #     NOTHING else. The provider's raised InvalidClientError on bad client
      #     credentials, answering 401 with an error body: a caller could tell
      #     "your credentials are wrong" from "that token is not valid".
      #   * The provider's rate limiter answered 429, which turns the throttle
      #     into a token-validity oracle — probe until throttled, then read the
      #     status code rather than the body. Core's renders the ordinary
      #     inactive response instead, deliberately.
      #   * Core's is 404-gated behind `config.oauth.introspection_enabled`, so
      #     an endpoint that answers questions about other people's tokens is
      #     not exposed by accident. The provider's was always on — and its own
      #     `config.provider.introspection_enabled` flag was never read.
      #
      # Only one thing was worth keeping: core cannot see
      # StandardId::Provider::RevokedToken. Core says so itself — access tokens
      # are stateless, "this engine cannot invalidate a stateless JWT before its
      # exp". This engine's revocation endpoint maintains exactly the jti
      # denylist that makes that possible. So rather than run two endpoints with
      # different answers, the denylist is contributed INTO core's.
      #
      # ## Coupling
      #
      # `#decode_token` is a private method of a non-public controller. That is
      # the same bargain the rest of this gem already makes (see
      # StandardId::Provider::Engine), and the reason the gemspec pins
      # `standard_id` to `~> 0.33` with a `compat` CI job watching it.
      #
      # Returning nil is the whole mechanism: core already treats a nil decode
      # as inactive and renders the bare `{"active": false}`, so a denylisted
      # token is indistinguishable from a forged one — which is what RFC 7662
      # §2.2 wants.
      module IntrospectionsControllerExt
        private

        def decode_token(token)
          payload = super
          return nil if payload.nil?

          jti = payload[:jti]
          return nil if jti.present? && StandardId::Provider::RevokedToken.revoked?(jti)

          payload
        end
      end
    end
  end
end
