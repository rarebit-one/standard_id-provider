class Account < ApplicationRecord
  validates :email, presence: true
  validates :name, presence: true
end
