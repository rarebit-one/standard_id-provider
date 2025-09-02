require "jwt"

module StandardId
  class JwtService
    ALGORITHM = "HS256"
    Session = Struct.new(:account_id, :client_id, :scopes, :grant_type, keyword_init: true) do
      def active?
        true
      end
    end

    def self.encode(payload, expires_in: 1.hour)
      payload[:exp] = expires_in.from_now.to_i
      payload[:iat] = Time.current.to_i

      JWT.encode(payload, secret_key, ALGORITHM)
    end

    def self.decode(token)
      decoded = JWT.decode(token, secret_key, true, { algorithm: ALGORITHM })
      decoded.first.with_indifferent_access
    rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::InvalidIatError
      nil
    end

    def self.decode_session(token)
      payload = decode(token)
      return unless payload

      scopes = if payload[:scope].is_a?(String)
        payload[:scope].split(" ")
      else
        Array(payload[:scope]).compact
      end

      Session.new(
        account_id: payload[:sub],
        client_id: payload[:client_id],
        scopes: scopes,
        grant_type: payload[:grant_type]
      )
    end

    private

    def self.secret_key
      Rails.application.secret_key_base
    end
  end
end
