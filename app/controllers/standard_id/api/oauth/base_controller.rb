module StandardId
  module Api
    module Oauth
      class BaseController < ActionController::API
        private
        def token_manager
          @token_manager ||= StandardId::Api::TokenManager.new(request)
        end
      end
    end
  end
end
