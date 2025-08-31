module StandardId
  class PasswordCredential < ApplicationRecord
    include StandardId::Credentiable

    has_secure_password

    validates :login, presence: true, uniqueness: true
    validates :password, length: { minimum: 8 }, confirmation: true, if: :validate_password?

    private

    def validate_password?
      password.present? || password_confirmation.present?
    end
  end
end
