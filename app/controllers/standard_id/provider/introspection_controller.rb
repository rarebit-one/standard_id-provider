module StandardId
  module Provider
    class IntrospectionController < ApplicationController
      # Throttle by IP (30 per 15 min) BEFORE client authentication so this
      # credential-guessable RFC 7662 endpoint can't be brute-forced. Override
      # with RATE_LIMIT_INTROSPECT_PER_IP.
      rate_limit to: (ENV["RATE_LIMIT_INTROSPECT_PER_IP"] || 30).to_i,
                 within: 15.minutes,
                 by: -> { request.remote_ip },
                 name: "provider-introspect-ip",
                 store: StandardId::RateLimitHandling::RATE_LIMIT_STORE

      before_action :authenticate_client!

      def create
        token = params[:token]

        if token.blank?
          render json: { active: false }
          return
        end

        payload = StandardId::JwtService.decode(token)

        if payload.nil?
          render json: { active: false }
          return
        end

        if payload[:jti].present? && RevokedToken.revoked?(payload[:jti])
          render json: { active: false }
          return
        end

        render json: {
          active: true,
          sub: payload[:sub],
          client_id: payload[:client_id],
          scope: payload[:scope],
          iss: payload[:iss],
          exp: payload[:exp],
          iat: payload[:iat],
          jti: payload[:jti],
          aud: payload[:aud],
          token_type: "Bearer"
        }.compact
      end
    end
  end
end
