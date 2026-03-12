module StandardId
  module Provider
    class ConsentController < ApplicationController
      include ActionController::Cookies

      before_action :require_authentication
      before_action :load_client

      def show
        render json: {
          client: {
            name: @client.name,
            description: @client.description
          },
          scopes: requested_scopes,
          authorization_params: authorization_params
        }
      end

      def create
        ConsentGrant.active.find_by(
          account: current_account,
          client_application: @client
        )&.revoke!

        ConsentGrant.create!(
          account: current_account,
          client_application: @client,
          scopes: authorization_params[:scope]
        )

        authorize_url = build_authorize_redirect
        redirect_to authorize_url, allow_other_host: true, status: :found
      end

      def destroy
        redirect_uri = authorization_params[:redirect_uri]

        if redirect_uri.present?
          deny_url = build_error_redirect(redirect_uri, "access_denied", "The user denied the consent request")
          redirect_to deny_url, allow_other_host: true, status: :found
        else
          render json: { error: "access_denied", error_description: "The user denied the consent request" }, status: :forbidden
        end
      end

      private

      def require_authentication
        return if current_account.present?

        render json: { error: "login_required", error_description: "Authentication is required" }, status: :unauthorized
      end

      def current_account
        @current_account ||= begin
          token_manager = StandardId::Web::TokenManager.new(request)
          session_manager = StandardId::Web::SessionManager.new(token_manager, request: request, session: session, cookies: cookies)
          session_manager.current_account
        end
      end

      def load_client
        @client = StandardId::ClientApplication.active.find_by(client_id: authorization_params[:client_id])
        unless @client
          raise StandardId::InvalidClientError, "Invalid client_id"
        end
      end

      def authorization_params
        @authorization_params ||= params.permit(
          :client_id, :redirect_uri, :scope, :state, :audience,
          :nonce, :response_type, :code_challenge, :code_challenge_method
        ).to_h.symbolize_keys
      end

      def requested_scopes
        authorization_params[:scope].to_s.split(/\s+/)
      end

      def build_authorize_redirect
        uri = URI.parse("#{StandardId.config.issuer}/api/authorize")
        uri.query = URI.encode_www_form(authorization_params.compact)
        uri.to_s
      end

      def build_error_redirect(redirect_uri, error, description)
        uri = URI.parse(redirect_uri)
        query = URI.decode_www_form(uri.query || "")
        query << ["error", error]
        query << ["error_description", description]
        query << ["state", authorization_params[:state]] if authorization_params[:state].present?
        uri.query = URI.encode_www_form(query)
        uri.to_s
      end
    end
  end
end
