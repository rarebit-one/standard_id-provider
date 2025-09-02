module StandardId
  module Web
    class TokenManager
      attr_reader :request

      def initialize(request)
        @request = request
      end

      def create_browser_session(account, remember_me: false)
        StandardId::BrowserSession.create!(
          account: account,
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          expires_at: remember_me ? 30.days.from_now : 24.hours.from_now # TODO: make these configurable
        )
      end

      def create_remember_token(password_credential)
        {
          value: password_credential.generate_token_for(:remember_me),
          expires: password_credential.expires_at,
          httponly: true,
          secure: request.ssl?,
          same_site: :lax
        }
      end
    end
  end
end
