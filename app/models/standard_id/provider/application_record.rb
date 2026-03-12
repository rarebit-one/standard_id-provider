module StandardId
  module Provider
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
