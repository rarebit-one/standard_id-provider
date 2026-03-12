module OAuthHelpers
  def create_oauth_client(name: "Test App", require_consent: false, scopes: "openid profile email")
    account = Account.create!(name: "Owner", email: "owner-#{SecureRandom.hex(4)}@example.com")
    client = StandardId::ClientApplication.create!(
      name: name,
      owner: account,
      require_consent: require_consent,
      redirect_uris: ["https://example.com/callback"]
    )
    credential = StandardId::ClientSecretCredential.create!(
      name: "default",
      client_application: client,
      client_id: client.client_id,
      client_secret: "test-client-secret",
      scopes: scopes
    )
    [client, credential]
  end

  def basic_auth_header(client_id, client_secret)
    encoded = Base64.strict_encode64("#{client_id}:#{client_secret}")
    { "Authorization" => "Basic #{encoded}" }
  end

  def generate_access_token(sub: nil, client_id: "test-client", scope: "openid profile", jti: nil, extra: {})
    claims = { sub: sub, client_id: client_id, scope: scope }
    claims[:jti] = jti || SecureRandom.uuid
    claims.merge!(extra)
    StandardId::JwtService.encode(claims)
  end

  def json_body
    JSON.parse(response.body)
  rescue JSON::ParserError
    {}
  end
end

RSpec.configure do |config|
  config.include OAuthHelpers
end
