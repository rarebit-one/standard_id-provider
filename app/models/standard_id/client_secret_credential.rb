module StandardId
  class ClientSecretCredential < ApplicationRecord
    include StandardId::Credentiable

    has_secure_password :client_secret

    before_validation :ensure_client_id, on: :create

    validates :name, presence: true

    validates :client_id, presence: true, uniqueness: true
    validates :active, inclusion: { in: [true, false] }

    scope :active, -> { where(active: true, revoked_at: nil) }

    def revoke!
      update!(active: false, revoked_at: Time.current)
    end

    def active?
      active && revoked_at.nil?
    end

    def scopes_array
      (scopes || "").split(" ").map(&:strip).reject(&:blank?)
    end

    def default_redirect_uri
      redirect_uris&.split(" ")&.first
    end

    private

    def ensure_client_id
      self.client_id ||= SecureRandom.hex(16)
    end
  end
end
