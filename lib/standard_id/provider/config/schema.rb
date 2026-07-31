StandardId::ConfigSchema.define do
  scope :provider do
    field :id_token_lifetime, type: :integer, default: 3600
    field :scopes_supported, type: :array, default: -> { %w[openid profile email offline_access] }
    field :claims_supported, type: :array, default: -> { %w[sub iss aud exp iat nonce auth_time at_hash email name email_verified] }
    field :subject_types_supported, type: :array, default: -> { %w[public] }
    # NOTE: there is deliberately no `introspection_enabled` here any more.
    # It was declared, documented as a switch, and never read by anything —
    # the endpoint it claimed to gate was always on. Introspection is now
    # core's endpoint, gated by `StandardId.config.oauth.introspection_enabled`
    # (which defaults to FALSE — a provider deployment must opt in).
    #
    # `revocation_enabled` had the same defect and is now actually enforced by
    # StandardId::Provider::RevocationController.
    field :revocation_enabled, type: :boolean, default: true
  end
end
