module StandardId
  module Oauth
    class BaseFlow
      attr_reader :params, :request

      def initialize(params, request)
        @params = params
        @request = request
      end

      class << self
        def expect_params(*keys)
          @expected_params ||= []
          @expected_params |= keys.flatten.map! { |k| k.to_sym }
        end

        def permit_params(*keys)
          @permitted_params ||= []
          @permitted_params |= keys.flatten.map! { |k| k.to_sym }
        end

        def expected_params
          Array(@expected_params).dup
        end

        def permitted_params
          exp = expected_params
          perm = Array(@permitted_params)
          configured = (exp + perm + [:grant_type]).uniq
          return configured
        end
      end

      def execute
        authenticate!
        generate_token_response
      end

      private

      def authenticate!
        raise NotImplementedError, "Subclasses must implement authenticate!"
      end

      def validate_client_secret!(client_id, client_secret)
        client_secret_credential = StandardId::ClientSecretCredential.active.find_by(client_id: client_id)
        unless client_secret_credential&.authenticate_client_secret(client_secret)
          raise StandardId::InvalidClientError, "Client authentication failed"
        end
      end

      def generate_token_response
        expires_in = token_expiry
        payload = build_jwt_payload(expires_in)
        access_token = StandardId::JwtService.encode(payload, expires_in: expires_in)

        response = {
          access_token: access_token,
          token_type: "Bearer",
          expires_in: expires_in.to_i
        }

        response[:scope] = token_scope if token_scope.present?
        response[:refresh_token] = generate_refresh_token if supports_refresh_token?

        response.compact
      end

      def build_jwt_payload(expires_in)
        {
          sub: subject_id,
          client_id: client_id,
          scope: token_scope,
          grant_type: grant_type,
          aud: audience
        }.compact
      end

      def token_expiry
        1.hour
      end

      def supports_refresh_token?
        false
      end

      def generate_refresh_token
        nil
      end

      # Abstract methods to be implemented by subclasses
      def subject_id
        raise NotImplementedError
      end

      def client_id
        raise NotImplementedError
      end

      def token_scope
        raise NotImplementedError
      end

      def grant_type
        raise NotImplementedError
      end

      def audience
        params[:audience]
      end
    end
  end
end
