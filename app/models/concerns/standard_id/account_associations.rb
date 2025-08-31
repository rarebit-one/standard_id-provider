module StandardId
  module AccountAssociations
    extend ActiveSupport::Concern

    included do
      has_many :identifiers, class_name: "StandardId::Identifier", dependent: :restrict_with_exception
      has_many :credentials, through: :identifiers, source: :credentials, dependent: :restrict_with_exception
      has_many :sessions, class_name: "StandardId::Session", dependent: :restrict_with_exception
    end
  end
end
