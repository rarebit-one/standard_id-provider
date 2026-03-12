module StandardId
  module Web
    class LogoutController < BaseController
      skip_before_action :require_browser_session!, only: [:create]

      before_action :redirect_if_not_authenticated

      def create
        revoke_current_session!
        redirect_to params[:redirect_uri] || root_path, notice: "Successfully signed out"
      end

      private

      def redirect_if_not_authenticated
        redirect_to params[:redirect_uri] || root_path unless authenticated?
      end
    end
  end
end
