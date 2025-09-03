module StandardId
  class Credential < ApplicationRecord
    belongs_to :identifier, class_name: "StandardId::Identifier"

    delegate :account, to: :identifier

    delegated_type :credentialable, types: %w[PasswordCredential ClientSecretCredential]

    # Internal alias for future flexibility with multiple subject types
    def subject
      account
    end
  end
end
