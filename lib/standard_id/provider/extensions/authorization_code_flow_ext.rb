module StandardId
  module Provider
    module Extensions
      module AuthorizationCodeFlowExt
        private

        def id_token_nonce
          @authorization_code&.nonce
        end
      end
    end
  end
end
