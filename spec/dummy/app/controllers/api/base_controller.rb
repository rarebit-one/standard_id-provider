module Api
  class BaseController < ApplicationController
    include StandardId::ApiAuthentication

    rescue_from StandardId::NotAuthenticatedError, with: :handle_not_authenticated
    rescue_from StandardId::ExpiredSessionError, with: :handle_expired_session
    rescue_from StandardId::RevokedSessionError, with: :handle_revoked_session

    before_action :verify_access_token!

    private

    def handle_not_authenticated(exception)
      render json: {
        error: "Authentication required",
        code: "NOT_AUTHENTICATED",
        message: exception.message
      }, status: :unauthorized
    end

    def handle_expired_session(exception)
      render json: {
        error: "Session expired",
        code: "EXPIRED_SESSION",
        message: exception.message
      }, status: :unauthorized
    end

    def handle_revoked_session(exception)
      render json: {
        error: "Session revoked",
        code: "REVOKED_SESSION",
        message: exception.message
      }, status: :unauthorized
    end
  end
end
