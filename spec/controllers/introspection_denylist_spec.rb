require "rails_helper"

# This engine no longer ships its own introspection endpoint. It contributes
# the StandardId::Provider::RevokedToken denylist into CORE's RFC 7662 endpoint
# (POST /oauth/introspect) via
# StandardId::Provider::Extensions::IntrospectionsControllerExt.
#
# Core has its own specs for the endpoint's RFC conformance; these cover only
# the part this gem adds — and the part core cannot do on its own, since it
# states plainly that it "cannot invalidate a stateless JWT before its exp".
RSpec.describe "Introspection denylist", type: :request do
  let(:client_app) { create_oauth_client }
  let(:credential) { client_app.last }
  let(:auth_headers) { basic_auth_header(credential.client_id, "test-client-secret") }

  describe "POST /api/oauth/introspect" do
    it "reports a token that is merely valid as active" do
      token = generate_access_token(sub: "user-1")

      post "/api/oauth/introspect", params: { token: token }, headers: auth_headers

      expect(json_body["active"]).to be true
      expect(json_body["sub"]).to eq("user-1")
    end

    it "reports a denylisted access token as inactive" do
      jti = SecureRandom.uuid
      token = generate_access_token(sub: "user-1", jti: jti)
      StandardId::Provider::RevokedToken.revoke!(jti: jti)

      post "/api/oauth/introspect", params: { token: token }, headers: auth_headers

      expect(json_body["active"]).to be false
    end

    # RFC 7662 §2.2 — a denylisted token must be indistinguishable from a
    # forged one. Leaking "this WAS a real token, and it was revoked" tells an
    # attacker their guess was structurally correct.
    it "reveals nothing beyond active: false for a denylisted token" do
      jti = SecureRandom.uuid
      token = generate_access_token(sub: "user-1", jti: jti)
      StandardId::Provider::RevokedToken.revoke!(jti: jti)

      post "/api/oauth/introspect", params: { token: token }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json_body.keys).to contain_exactly("active")
    end

    it "leaves a token whose jti was never denylisted alone" do
      token = generate_access_token(sub: "user-1", jti: SecureRandom.uuid)
      StandardId::Provider::RevokedToken.revoke!(jti: SecureRandom.uuid)

      post "/api/oauth/introspect", params: { token: token }, headers: auth_headers

      expect(json_body["active"]).to be true
    end
  end
end
