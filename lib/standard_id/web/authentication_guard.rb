module StandardId
  module Web
    class AuthenticationGuard
      def require_session!(session_manager, session:, request:)
        session[:return_to_after_authenticating] = request.url

        browser_session = session_manager.current_session

        if browser_session.blank?
          raise StandardId::NotAuthenticatedError
        elsif browser_session.expired?
          session_manager.clear_session!
          raise StandardId::ExpiredSessionError
        elsif browser_session.revoked?
          session_manager.clear_session!
          raise StandardId::RevokedSessionError
        end

        browser_session
      end
    end
  end
end
