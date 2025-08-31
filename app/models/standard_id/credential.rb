module StandardId
  class Credential < ApplicationRecord
    belongs_to :identifier, class_name: "StandardId::Identifier"
    belongs_to :credentialable, polymorphic: true
  end
end
