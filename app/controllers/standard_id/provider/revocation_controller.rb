module StandardId
  module Provider
    class RevocationController < ApplicationController
      # Throttle by IP (30 per 15 min) BEFORE client authentication so this
      # credential-guessable RFC 7009 endpoint can't be brute-forced. Override
      # with RATE_LIMIT_REVOKE_PER_IP.
      rate_limit to: (ENV["RATE_LIMIT_REVOKE_PER_IP"] || 30).to_i,
                 within: 15.minutes,
                 by: -> { request.remote_ip },
                 name: "provider-revoke-ip",
                 store: StandardId::RateLimitHandling::RATE_LIMIT_STORE

      before_action :require_revocation_enabled!
      before_action :authenticate_client!

      def create
        token = params[:token]
        return head :ok if token.blank?

        payload = StandardId::JwtService.decode(token)
        return head :ok if payload.nil?

        jti = payload[:jti]
        return head :ok if jti.blank?

        expires_at = payload[:exp] ? Time.at(payload[:exp]) : 1.day.from_now

        RevokedToken.revoke!(
          jti: jti,
          client_id: @client_credential.client_id,
          token_type: params[:token_type_hint],
          expires_at: expires_at
        )

        head :ok
      end

      private

      # `config.provider.revocation_enabled` was declared from the start and
      # read by nothing, so the switch silently did not work. Enforced here,
      # 404 rather than 403 so a disabled endpoint is indistinguishable from
      # one that does not exist — matching how core gates introspection.
      def require_revocation_enabled!
        head(:not_found) unless StandardId.config.provider.revocation_enabled
      end
    end
  end
end
