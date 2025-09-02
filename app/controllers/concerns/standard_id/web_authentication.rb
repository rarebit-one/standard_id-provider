module StandardId
  module WebAuthentication
    extend ActiveSupport::Concern

    included do
      helper_method :current_account, :authenticated?
    end

    delegate :current_session, :current_account, :revoke_current_session!, to: :session_manager

    private

    def authenticated?
      current_account.present?
    end

    def require_browser_session!
      authentication_guard.require_session!(session_manager, session: session, request: request)
    end

    def after_authentication_url
      # TODO: add configurable value
      session.delete(:return_to_after_authenticating) || "/"
    end

    def sign_in_account(login, password)
      StandardId::PasswordCredential.find_by(login:).authenticate(password).tap do |password_credential|
        session_manager.sign_in_account(password_credential.account)
      end
    end

    def session_manager
      @session_manager ||= StandardId::Web::SessionManager.new(token_manager, request: request, session: session, cookies: cookies)
    end

    def token_manager
      @token_manager ||= StandardId::Web::TokenManager.new(request)
    end

    def authentication_guard
      @authentication_guard ||= StandardId::Web::AuthenticationGuard.new
    end
  end
end
