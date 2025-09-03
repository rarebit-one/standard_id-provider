module StandardId
  module Api
    module Oauth
      class BaseController < StandardId::Api::BaseController
        rescue_from StandardId::OAuthError, with: :handle_oauth_error

        private

        def token_manager
          @token_manager ||= StandardId::Api::TokenManager.new(request)
        end

        def handle_oauth_error(exception)
          error_code = exception.respond_to?(:oauth_error_code) ? exception.oauth_error_code : :invalid_request
          status = exception.respond_to?(:http_status) ? exception.http_status : :bad_request
          description = exception.message.presence || "An error occurred processing the request"

          render json: {
            error: error_code.to_s,
            error_description: description
          }, status: status
        end
      end
    end
  end
end
