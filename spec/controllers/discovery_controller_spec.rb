require "rails_helper"

RSpec.describe "OIDC Discovery", type: :request do
  describe "GET /.well-known/openid-configuration" do
    before { get "/.well-known/openid-configuration" }

    it "returns 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "includes the issuer" do
      expect(json_body["issuer"]).to eq(StandardId.config.issuer)
    end

    it "includes required endpoints" do
      body = json_body
      expect(body["authorization_endpoint"]).to be_present
      expect(body["token_endpoint"]).to be_present
      expect(body["userinfo_endpoint"]).to be_present
      expect(body["jwks_uri"]).to be_present
    end

    it "includes supported scopes" do
      expect(json_body["scopes_supported"]).to include("openid")
    end

    it "includes id_token_signing_alg_values_supported" do
      expect(json_body["id_token_signing_alg_values_supported"]).to be_present
    end
  end
end
