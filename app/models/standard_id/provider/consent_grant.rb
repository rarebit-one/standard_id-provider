module StandardId
  module Provider
    class ConsentGrant < ApplicationRecord
      self.table_name = "standard_id_consent_grants"

      belongs_to :account, class_name: StandardId.config.account_class_name
      belongs_to :client_application, class_name: "StandardId::ClientApplication"

      validates :scopes, presence: true

      scope :active, -> { where(revoked_at: nil) }
      scope :revoked, -> { where.not(revoked_at: nil) }

      before_validation :set_granted_at, on: :create

      def revoke!
        update!(revoked_at: Time.current)
      end

      def covers_scopes?(requested_scopes)
        granted = scopes.to_s.split(/\s+/)
        (requested_scopes - granted).empty?
      end

      private

      def set_granted_at
        self.granted_at ||= Time.current
      end
    end
  end
end
