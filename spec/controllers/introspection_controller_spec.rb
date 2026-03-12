require "rails_helper"

RSpec.describe StandardId::Provider::IntrospectionController, type: :request do
  let(:client_app) { create_oauth_client }
  let(:client) { client_app.first }
  let(:credential) { client_app.last }
  let(:auth_headers) { basic_auth_header(credential.client_id, "test-client-secret") }

  describe "POST /api/provider/introspect" do
    it "returns active: false for missing token" do
      post "/api/provider/introspect", headers: auth_headers

      expect(json_body["active"]).to be false
    end

    it "returns active: false for invalid token" do
      post "/api/provider/introspect", params: { token: "invalid" }, headers: auth_headers

      expect(json_body["active"]).to be false
    end

    it "returns active: true for valid token" do
      token = generate_access_token(sub: "user-1")

      post "/api/provider/introspect", params: { token: token }, headers: auth_headers

      expect(json_body["active"]).to be true
      expect(json_body["sub"]).to eq("user-1")
    end

    it "returns active: false for revoked token" do
      jti = SecureRandom.uuid
      token = generate_access_token(sub: "user-1", jti: jti)
      StandardId::Provider::RevokedToken.revoke!(jti: jti)

      post "/api/provider/introspect", params: { token: token }, headers: auth_headers

      expect(json_body["active"]).to be false
    end

    it "requires client authentication" do
      post "/api/provider/introspect"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
