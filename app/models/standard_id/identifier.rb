module StandardId
  class Identifier < ApplicationRecord
    belongs_to :account, class_name: StandardId.config.account_class_name

    scope :verified, -> { where.not(verified_at: nil) }
    scope :unverified, -> { where(verified_at: nil) }

    # Shared validations
    validates :value, presence: true, uniqueness: { scope: [:account_id, :type] }

    def verified?
      verified_at.present?
    end

    def verify!
      update!(verified_at: Time.current)
    end

    def unverify!
      update!(verified_at: nil)
    end
  end
end
