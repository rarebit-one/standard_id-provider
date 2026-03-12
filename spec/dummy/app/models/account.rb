class Account < ApplicationRecord
  include StandardId::AccountAssociations
end
