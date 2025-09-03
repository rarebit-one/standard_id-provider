module StandardId
  module Oauth
    class AuthorizationFlow < BaseRequestFlow
      attr_reader :params, :request, :current_account

      def initialize(params, request, current_account: nil)
        @params = params
        @request = request
        @current_account = current_account
      end

      class << self
        def extra_permitted_keys
          [:response_type]
        end
      end

      def execute
        validate_params!
        authenticate_client!
        generate_authorization_response
      end

      private

      def validate_params!
        if params[:response_type].blank?
          raise StandardId::InvalidRequestError, "The response_type parameter is required"
        end

        if params[:client_id].blank?
          raise StandardId::InvalidRequestError, "The client_id parameter is required"
        end
      end

      def authenticate_client!
        @client_credential = StandardId::ClientSecretCredential.active.find_by(client_id: params[:client_id])
        unless @client_credential
          raise StandardId::InvalidClientError, "Invalid client_id"
        end

        if params[:redirect_uri].present?
          valid_redirect_uris = @client_credential.redirect_uris&.split(" ") || []
          unless valid_redirect_uris.include?(params[:redirect_uri])
            raise StandardId::InvalidRequestError, "Invalid redirect_uri"
          end
        end
      end

      def generate_authorization_response
        raise NotImplementedError, "Subclasses must implement generate_authorization_response"
      end

      def build_redirect_uri(base_uri, params_hash)
        uri = URI.parse(base_uri)
        query_params = URI.decode_www_form(uri.query || "")

        params_hash.each do |key, value|
          query_params << [key.to_s, value.to_s] if value.present?
        end

        uri.query = URI.encode_www_form(query_params)
        uri.to_s
      end

      def build_fragment_uri(base_uri, params_hash)
        uri = URI.parse(base_uri)
        fragment_params = params_hash.compact.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join("&")
        uri.fragment = fragment_params
        uri.to_s
      end

      def redirect_uri
        params[:redirect_uri] || @client_credential.default_redirect_uri
      end

      def state
        params[:state]
      end

      def scope
        params[:scope]
      end

      def audience
        params[:audience]
      end
    end
  end
end
