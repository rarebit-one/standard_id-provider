module StandardId
  class Credential < ApplicationRecord
    belongs_to :identifier, class_name: "StandardId::Identifier"

    delegated_type :credentialable, types: %w[PasswordCredential ClientSecretCredential]
  end
end
