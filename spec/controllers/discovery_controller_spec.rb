require "rails_helper"

RSpec.describe StandardId::Provider::DiscoveryController, type: :request do
  describe "GET /.well-known/openid-configuration" do
    before do
      get "/.well-known/openid-configuration"
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "includes issuer" do
      expect(json_body["issuer"]).to eq(StandardId.config.issuer)
    end

    it "includes required OIDC endpoints" do
      expect(json_body["authorization_endpoint"]).to be_present
      expect(json_body["token_endpoint"]).to be_present
      expect(json_body["jwks_uri"]).to be_present
    end

    it "includes supported scopes" do
      expect(json_body["scopes_supported"]).to include("openid")
    end

    it "includes id_token_signing_alg_values_supported" do
      expect(json_body["id_token_signing_alg_values_supported"]).to be_an(Array)
      expect(json_body["id_token_signing_alg_values_supported"]).not_to be_empty
    end
  end
end
