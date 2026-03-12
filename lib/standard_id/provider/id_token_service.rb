module StandardId
  module Provider
    class IdTokenService
      class << self
        def generate(subject_id:, client_id:, nonce: nil, access_token: nil, authorization_code: nil, auth_time: nil, extra_claims: {})
          payload = {
            sub: subject_id,
            aud: client_id,
            nonce: nonce,
            auth_time: auth_time&.to_i
          }.compact

          payload[:at_hash] = compute_half_hash(access_token) if access_token.present?
          payload[:c_hash] = compute_half_hash(authorization_code) if authorization_code.present?
          payload.merge!(extra_claims.symbolize_keys) if extra_claims.present?

          expires_in = StandardId.config.provider.id_token_lifetime.seconds

          StandardId::JwtService.encode(payload, expires_in: expires_in)
        end

        private

        def compute_half_hash(value)
          digest = hash_algorithm.digest(value)
          Base64.urlsafe_encode64(digest[0, digest.length / 2], padding: false)
        end

        def hash_algorithm
          case StandardId::JwtService.algorithm
          when /256$/ then OpenSSL::Digest::SHA256
          when /384$/ then OpenSSL::Digest::SHA384
          when /512$/ then OpenSSL::Digest::SHA512
          else OpenSSL::Digest::SHA256
          end
        end
      end
    end
  end
end
