module StandardId
  module Provider
    class RevocationController < BaseController
      before_action :authenticate_client!

      # RFC 7009: Always returns 200 OK regardless of token validity
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
    end
  end
end
