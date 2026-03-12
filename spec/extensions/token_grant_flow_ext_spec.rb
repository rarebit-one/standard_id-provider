require "rails_helper"

RSpec.describe "TokenGrantFlowExt (via client_credentials)", type: :request do
  describe "POST /api/oauth/token with client_credentials grant" do
    context "when openid scope is present" do
      let!(:client_and_credential) { create_oauth_client(scopes: "openid profile email") }
      let(:credential) { client_and_credential[1] }

      it "includes id_token in the response" do
        post "/api/oauth/token", params: {
          grant_type: "client_credentials",
          client_id: credential.client_id,
          client_secret: "test-client-secret",
          audience: "test-service",
          scope: "openid profile"
        }

        expect(response).to have_http_status(:ok)
        body = json_body
        expect(body["access_token"]).to be_present
        expect(body["id_token"]).to be_present
      end
    end

    context "when openid scope is not present" do
      let!(:client_and_credential) { create_oauth_client(scopes: "read write") }
      let(:credential) { client_and_credential[1] }

      it "does not include id_token" do
        post "/api/oauth/token", params: {
          grant_type: "client_credentials",
          client_id: credential.client_id,
          client_secret: "test-client-secret",
          audience: "test-service",
          scope: "read write"
        }

        expect(response).to have_http_status(:ok)
        body = json_body
        expect(body["access_token"]).to be_present
        expect(body["id_token"]).to be_nil
      end
    end
  end
end
