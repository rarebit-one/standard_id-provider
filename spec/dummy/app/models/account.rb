class Account < ApplicationRecord
  include StandardId::AccountAssociations

  validates :email, presence: true
  validates :name, presence: true
end
