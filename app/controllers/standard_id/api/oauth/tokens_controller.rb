require "base64"

module StandardId
  module Api
    module Oauth
      class TokensController < ActionController::API
        before_action :validate_grant_type
        before_action :resolve_client_credentials
        before_action :authenticate_client!

        def create
          expires_in = 1.hour

          payload = {
            sub: @credential.account.id,
            client_id: @credential.client_id,
            scope: @credential.scopes_array.join(" "),
            grant_type: "client_credentials"
          }

          access_token = StandardId::JwtService.encode(payload, expires_in: expires_in)

          render json: {
            access_token: access_token,
            token_type: "Bearer",
            expires_in: expires_in.to_i,
            scope: @credential.scopes,
            created_at: Time.current.to_i
          }
        end

        private

        def validate_grant_type
          return if params[:grant_type] == "client_credentials"
          raise StandardId::UnsupportedGrantTypeError, "Only client_credentials is supported"
        end

        def resolve_client_credentials
          @client_id, @client_secret = extract_basic_credentials || [params[:client_id], params[:client_secret]]
          if @client_id.blank? || @client_secret.blank?
            raise StandardId::MissingClientSecretCredentialsError, "Missing client credentials"
          end
        end

        def authenticate_client!
          @credential = StandardId::ClientSecretCredential.active.find_by(client_id: @client_id)
          unless @credential&.authenticate_client_secret(@client_secret)
            raise StandardId::InvalidClientSecretCredentialsError, "Invalid client credentials"
          end
        end

        def extract_basic_credentials
          auth = request.authorization
          return unless auth&.start_with?("Basic ")

          decoded = Base64.decode64(auth.split(" ", 2).last || "")
          return unless decoded.include?(":")

          decoded.split(":", 2)
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
