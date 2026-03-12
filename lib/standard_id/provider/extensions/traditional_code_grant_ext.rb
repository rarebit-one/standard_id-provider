module StandardId
  module Provider
    module Extensions
      module TraditionalCodeGrantExt
        private

        def store_authorization_code
          StandardId::AuthorizationCode.issue!(
            plaintext_code: authorization_code,
            client_id: params[:client_id],
            redirect_uri: params[:redirect_uri],
            scope: params[:scope],
            audience: params[:audience],
            account: params[:current_account],
            code_challenge: params[:code_challenge],
            code_challenge_method: params[:code_challenge_method],
            nonce: params[:nonce],
            metadata: { state: params[:state] }.compact
          )
        end
      end
    end
  end
end
