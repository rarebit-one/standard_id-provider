module StandardId
  class PasswordCredential < ApplicationRecord
    include StandardId::Credentiable

    has_secure_password

    generates_token_for :remember_me, expires_in: 30.days do
      password_digest
    end

    validates :login, presence: true, uniqueness: true
    validates :password, length: { minimum: 8 }, confirmation: true, if: :validate_password?

    private

    def validate_password?
      password.present? || password_confirmation.present?
    end
  end
end
