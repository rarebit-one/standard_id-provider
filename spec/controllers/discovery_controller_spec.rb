require "rails_helper"

RSpec.describe StandardId::Provider::DiscoveryController, type: :request do
  # The dummy sets `c.oauth.discovery_endpoint_base` to
  # `->(request:) { "#{request.base_url}/api" }` and mounts ApiEngine under
  # `/api`, so this is where the endpoints actually are.
  let(:endpoint_base) { "http://www.example.com/api" }

  describe "GET /.well-known/openid-configuration" do
    before { get "/.well-known/openid-configuration" }

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "emits the configured issuer verbatim" do
      expect(json_body["issuer"]).to eq("https://issuer.example.com")
    end

    # The regression this controller's rewrite exists for. Endpoints used to be
    # interpolated as "#{issuer}/api/..." — the issuer host with a hardcoded
    # mount prefix — which advertised URLs that 404 for any app whose issuer
    # host is not the serving origin, or whose ApiEngine is not at /api.
    it "hangs endpoints off the resolved endpoint base, not the issuer" do
      expect(json_body["authorization_endpoint"]).to eq("#{endpoint_base}/authorize")
      expect(json_body["token_endpoint"]).to eq("#{endpoint_base}/oauth/token")
      expect(json_body["userinfo_endpoint"]).to eq("#{endpoint_base}/userinfo")
      expect(json_body["introspection_endpoint"]).to eq("#{endpoint_base}/oauth/introspect")
    end

    it "does not leak the issuer host into any endpoint" do
      advertised = json_body.except("issuer").values.grep(String).grep(%r{\Ahttps?://})
      expect(advertised).not_to be_empty
      expect(advertised).to all(start_with("http://www.example.com"))
    end

    # This engine's revoke action, not core's, because this one writes the
    # denylist that introspection consults. Follows the Provider engine mount.
    it "advertises this engine's revocation endpoint" do
      expect(json_body["revocation_endpoint"]).to eq("http://www.example.com/api/provider/revoke")
    end

    it "includes the configured provider metadata" do
      expect(json_body["scopes_supported"]).to include("openid")
      expect(json_body["subject_types_supported"]).to eq(%w[public])
      expect(json_body["claims_supported"]).to include("sub")
    end

    it "includes id_token_signing_alg_values_supported" do
      expect(json_body["id_token_signing_alg_values_supported"]).to be_an(Array)
      expect(json_body["id_token_signing_alg_values_supported"]).not_to be_empty
    end

    # No longer advertised — see the controller comment. `token` promised an
    # implicit flow nothing implements; `plain` invited a PKCE downgrade core
    # rejects.
    it "advertises only the flows and PKCE methods that actually work" do
      expect(json_body["response_types_supported"]).to eq(%w[code])
      expect(json_body["code_challenge_methods_supported"]).to eq(%w[S256])
    end
  end

  describe "introspection advertisement" do
    it "is omitted when the host has not enabled core's endpoint" do
      allow(StandardId.config.oauth).to receive(:introspection_enabled).and_return(false)

      get "/.well-known/openid-configuration"

      expect(json_body).not_to have_key("introspection_endpoint")
    end
  end

  describe "host overrides" do
    it "lets discovery_metadata_overrides win over the provider members" do
      allow(StandardId.config.oauth).to receive(:discovery_metadata_overrides)
        .and_return({ scopes_supported: %w[openid mcp] })

      get "/.well-known/openid-configuration"

      expect(json_body["scopes_supported"]).to eq(%w[openid mcp])
    end

    it "removes a member set to nil" do
      allow(StandardId.config.oauth).to receive(:discovery_metadata_overrides)
        .and_return({ claims_supported: nil })

      get "/.well-known/openid-configuration"

      expect(json_body).not_to have_key("claims_supported")
    end
  end

  describe "when no issuer is configured" do
    it "404s rather than advertising a document with a null issuer" do
      allow(StandardId.config).to receive(:issuer).and_return(nil)

      get "/.well-known/openid-configuration"

      expect(response).to have_http_status(:not_found)
    end
  end
end
