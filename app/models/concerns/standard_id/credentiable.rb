module StandardId
  module Credentiable
    extend ActiveSupport::Concern

    included do
      has_one :credential, as: :credentialable, class_name: "StandardId::Credential", dependent: :restrict_with_exception
    end
  end
end
