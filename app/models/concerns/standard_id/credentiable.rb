module StandardId
  module Credentiable
    extend ActiveSupport::Concern

    included do
      has_one :credential, as: :credentialable, touch: true
      accepts_nested_attributes_for :credential

      delegate :account, to: :credential
    end
  end
end
