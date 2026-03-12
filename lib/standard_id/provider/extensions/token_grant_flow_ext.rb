module StandardId
  module Provider
    module Extensions
      module TokenGrantFlowExt
        private

        def generate_token_response
          response = super

          if openid_scope_requested? && subject_id.present?
            response[:id_token] = Provider::IdTokenService.generate(
              subject_id: subject_id,
              client_id: client_id,
              nonce: id_token_nonce,
              access_token: response[:access_token],
              auth_time: id_token_auth_time
            )
          end

          response
        end

        def build_jwt_payload(expires_in)
          payload = super
          payload[:jti] = SecureRandom.uuid
          payload
        end

        def openid_scope_requested?
          current_scopes.include?("openid")
        end

        # Subclass extensions can override these to provide values
        def id_token_nonce
          nil
        end

        def id_token_auth_time
          nil
        end
      end
    end
  end
end
