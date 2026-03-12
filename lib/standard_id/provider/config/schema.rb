require "standard_config"

StandardConfig.schema.draw do
  scope :provider do
    field :id_token_lifetime, type: :integer, default: 3600 # 1 hour in seconds
    field :scopes_supported, type: :array, default: -> { %w[openid profile email offline_access] }
    field :claims_supported, type: :array, default: -> { %w[sub iss aud exp iat nonce auth_time at_hash email name email_verified] }
    field :subject_types_supported, type: :array, default: -> { %w[public] }
    field :introspection_enabled, type: :boolean, default: true
    field :revocation_enabled, type: :boolean, default: true
  end
end
