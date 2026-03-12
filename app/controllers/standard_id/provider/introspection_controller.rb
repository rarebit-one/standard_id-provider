module StandardId
  module Provider
    class IntrospectionController < ApplicationController
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
