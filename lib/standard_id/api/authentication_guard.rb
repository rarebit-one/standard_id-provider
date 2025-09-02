module StandardId
  module Api
    class AuthenticationGuard
      def require_session!(session_manager)
        api_session = session_manager.current_session

        if api_session.blank?
          raise StandardId::NotAuthenticatedError, "Invalid or missing access token"
        elsif api_session.respond_to?(:expired?) && api_session.expired?
          raise StandardId::ExpiredSessionError, "Session has expired"
        elsif api_session.respond_to?(:revoked?) && api_session.revoked?
          session_manager.clear_session!
          raise StandardId::RevokedSessionError, "Session has been revoked"
        end

        api_session
      end
    end
  end
end
