require "rails_helper"

RSpec.describe "Token Introspection", type: :request do
  let!(:client_and_credential) { create_oauth_client }
  let(:client) { client_and_credential[0] }
  let(:credential) { client_and_credential[1] }
  let(:auth_header) { basic_auth_header(credential.client_id, "test-client-secret") }

  describe "POST /api/provider/introspect" do
    context "with a valid token" do
      let(:token) { generate_access_token(sub: "user-1", client_id: credential.client_id) }

      it "returns active: true" do
        post "/api/provider/introspect", params: { token: token }, headers: auth_header
        expect(response).to have_http_status(:ok)
        expect(json_body["active"]).to be true
        expect(json_body["sub"]).to eq("user-1")
      end
    end

    context "with an empty token" do
      it "returns active: false" do
        post "/api/provider/introspect", params: { token: "" }, headers: auth_header
        expect(response).to have_http_status(:ok)
        expect(json_body["active"]).to be false
      end
    end

    context "with a revoked token" do
      let(:jti) { SecureRandom.uuid }
      let(:token) { generate_access_token(sub: "user-1", client_id: credential.client_id, jti: jti) }

      it "returns active: false" do
        StandardId::Provider::RevokedToken.revoke!(jti: jti, expires_at: 1.hour.from_now)
        post "/api/provider/introspect", params: { token: token }, headers: auth_header
        expect(response).to have_http_status(:ok)
        expect(json_body["active"]).to be false
      end
    end

    context "without client authentication" do
      it "returns 401" do
        post "/api/provider/introspect", params: { token: "some-token" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with invalid client credentials" do
      it "returns 401" do
        post "/api/provider/introspect",
          params: { token: "some-token" },
          headers: basic_auth_header(credential.client_id, "wrong-secret")
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
