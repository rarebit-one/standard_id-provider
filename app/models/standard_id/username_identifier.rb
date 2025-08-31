module StandardId
  class UsernameIdentifier < Identifier
    validates :value, format: { with: /\A[a-zA-Z0-9_]+\z/ }
  end
end
