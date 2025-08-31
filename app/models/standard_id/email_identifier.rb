module StandardId
  class EmailIdentifier < Identifier
    validates :value, format: { with: URI::MailTo::EMAIL_REGEXP }
  end
end
