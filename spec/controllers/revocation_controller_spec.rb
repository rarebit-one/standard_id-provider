require "rails_helper"

RSpec.describe StandardId::Provider::RevocationController, type: :request do
  let(:client_app) { create_oauth_client }
  let(:client) { client_app.first }
  let(:credential) { client_app.last }
  let(:auth_headers) { basic_auth_header(credential.client_id, "test-client-secret") }

  describe "POST /api/provider/revoke" do
    it "returns 200 for blank token" do
      post "/api/provider/revoke", headers: auth_headers

      expect(response).to have_http_status(:ok)
    end

    it "returns 200 for invalid token" do
      post "/api/provider/revoke", params: { token: "invalid" }, headers: auth_headers

      expect(response).to have_http_status(:ok)
    end

    it "revokes a valid token" do
      jti = SecureRandom.uuid
      token = generate_access_token(sub: "user-1", jti: jti)

      post "/api/provider/revoke", params: { token: token }, headers: auth_headers

      expect(StandardId::Provider::RevokedToken.revoked?(jti)).to be true
    end

    it "is idempotent" do
      jti = SecureRandom.uuid
      token = generate_access_token(sub: "user-1", jti: jti)

      2.times do
        post "/api/provider/revoke", params: { token: token }, headers: auth_headers
      end

      expect(response).to have_http_status(:ok)
    end

    it "404s when config.provider.revocation_enabled is off" do
      allow(StandardId.config.provider).to receive(:revocation_enabled).and_return(false)

      post "/api/provider/revoke", params: { token: "x" }, headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end

    it "requires client authentication" do
      post "/api/provider/revoke"

      expect(response).to have_http_status(:unauthorized)
    end

    # The round trip that justifies this engine existing: revoking here writes
    # the denylist, and CORE's introspection endpoint reads it. Core cannot do
    # this alone — access tokens are stateless and it has nothing to look up.
    it "revoked token shows inactive on core's introspection endpoint" do
      jti = SecureRandom.uuid
      token = generate_access_token(sub: "user-1", jti: jti)

      post "/api/provider/revoke", params: { token: token }, headers: auth_headers
      post "/api/oauth/introspect", params: { token: token }, headers: auth_headers

      expect(json_body["active"]).to be false
    end
  end
end
