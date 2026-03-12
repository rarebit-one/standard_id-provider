module StandardId
  module Provider
    class RevokedToken < ApplicationRecord
      self.table_name = "standard_id_revoked_tokens"

      validates :jti, presence: true, uniqueness: true

      scope :active, -> { where("expires_at > ?", Time.current) }

      def self.revoke!(jti:, client_id: nil, token_type: nil, expires_at: nil)
        create!(
          jti: jti,
          client_id: client_id,
          token_type: token_type,
          revoked_at: Time.current,
          expires_at: expires_at || 1.day.from_now
        )
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        # Already revoked — idempotent per RFC 7009
      end

      def self.revoked?(jti)
        where(jti: jti).exists?
      end

      def self.cleanup_expired!
        where("expires_at <= ?", Time.current).delete_all
      end
    end
  end
end
