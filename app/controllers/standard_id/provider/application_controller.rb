module StandardId
  module Provider
    class ApplicationController < ActionController::API
      rescue_from StandardId::OAuthError do |e|
        render json: { error: e.oauth_error_code, error_description: e.message }, status: e.http_status
      end

      private

      def authenticate_client!
        extract_client_credentials_from_basic_auth

        @client_credential = StandardId::ClientSecretCredential.active.find_by(client_id: params[:client_id])

        unless @client_credential&.authenticate_client_secret(params[:client_secret])
          raise StandardId::InvalidClientError, "Client authentication failed"
        end

        @client_credential
      end

      def extract_client_credentials_from_basic_auth
        auth_header = request.headers["Authorization"]
        return unless auth_header&.start_with?("Basic ")

        if params[:client_id].present? || params[:client_secret].present?
          raise StandardId::InvalidRequestError,
            "Client credentials must be sent via Authorization header OR request body, not both"
        end

        decoded = Base64.strict_decode64(auth_header.split(" ", 2).last)
        client_id, client_secret = decoded.split(":", 2)
        params[:client_id] = CGI.unescape(client_id)
        params[:client_secret] = CGI.unescape(client_secret)
      rescue ArgumentError
        raise StandardId::InvalidClientError, "Invalid Basic authentication encoding"
      end
    end
  end
end
