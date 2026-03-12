module StandardId
  module Provider
    module Extensions
      module AuthorizationFlowExt
        private

        def generate_authorization_response
          if consent_required? && !consent_granted?
            return redirect_to_consent
          end

          super
        end

        def common_subflow_params(flow_params)
          super.merge(nonce: flow_params[:nonce])
        end

        def consent_required?
          @client&.require_consent? && openid_scope_requested?
        end

        def openid_scope_requested?
          scope.to_s.split(/\s+/).include?("openid")
        end

        def consent_granted?
          return false unless current_account

          grant = StandardId::Provider::ConsentGrant
            .active
            .find_by(account: current_account, client_application: @client)
          return false unless grant

          requested = scope.to_s.split(/\s+/).sort
          granted = grant.scopes.to_s.split(/\s+/).sort
          (requested - granted).empty?
        end

        def redirect_to_consent
          consent_params = {
            client_id: params[:client_id],
            redirect_uri: redirect_uri,
            scope: scope,
            state: state,
            audience: audience,
            nonce: params[:nonce],
            response_type: params[:response_type],
            code_challenge: params[:code_challenge],
            code_challenge_method: params[:code_challenge_method]
          }.compact

          consent_url = StandardId::Provider::Engine.routes.url_helpers.consent_path(consent_params)
          { redirect_to: consent_url, status: :found }
        end
      end
    end
  end
end
