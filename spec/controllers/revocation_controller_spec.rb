require "rails_helper"

RSpec.describe "Token Revocation", type: :request do
  let!(:client_and_credential) { create_oauth_client }
  let(:client) { client_and_credential[0] }
  let(:credential) { client_and_credential[1] }
  let(:auth_header) { basic_auth_header(credential.client_id, "test-client-secret") }

  describe "POST /api/provider/revoke" do
    context "with a valid token" do
      let(:jti) { SecureRandom.uuid }
      let(:token) { generate_access_token(sub: "user-1", client_id: credential.client_id, jti: jti) }

      it "returns 200 OK and revokes the token" do
        post "/api/provider/revoke", params: { token: token }, headers: auth_header
        expect(response).to have_http_status(:ok)
        expect(StandardId::Provider::RevokedToken.revoked?(jti)).to be true
      end
    end

    context "with an empty token" do
      it "returns 200 OK per RFC 7009" do
        post "/api/provider/revoke", params: { token: "" }, headers: auth_header
        expect(response).to have_http_status(:ok)
      end
    end

    context "with an invalid/unparseable token" do
      it "returns 200 OK per RFC 7009" do
        post "/api/provider/revoke", params: { token: "garbage" }, headers: auth_header
        expect(response).to have_http_status(:ok)
      end
    end

    context "revocation is idempotent" do
      let(:jti) { SecureRandom.uuid }
      let(:token) { generate_access_token(sub: "user-1", client_id: credential.client_id, jti: jti) }

      it "returns 200 OK on second revocation" do
        post "/api/provider/revoke", params: { token: token }, headers: auth_header
        expect(response).to have_http_status(:ok)

        post "/api/provider/revoke", params: { token: token }, headers: auth_header
        expect(response).to have_http_status(:ok)
      end
    end

    context "without client authentication" do
      it "returns 401" do
        post "/api/provider/revoke", params: { token: "some-token" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with token_type_hint" do
      let(:jti) { SecureRandom.uuid }
      let(:token) { generate_access_token(sub: "user-1", client_id: credential.client_id, jti: jti) }

      it "stores the token_type_hint" do
        post "/api/provider/revoke", params: { token: token, token_type_hint: "access_token" }, headers: auth_header
        expect(response).to have_http_status(:ok)

        revoked = StandardId::Provider::RevokedToken.find_by(jti: jti)
        expect(revoked.token_type).to eq("access_token")
      end
    end
  end
end
