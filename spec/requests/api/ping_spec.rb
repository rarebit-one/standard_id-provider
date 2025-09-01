require "rails_helper"

RSpec.describe "API Ping", type: :request do
  let(:account) { Account.create!(name: "Test Service", email: "service@example.com") }

  context "when authenticated" do
    let(:service_session) do
      StandardId::ServiceSession.create!(
        account: account,
        service_name: "test-service",
        service_version: "1.0.0",
        expires_at: StandardId::ServiceSession.default_expiry
      )
    end

    let(:auth_headers) do
      { "Authorization" => "Bearer #{service_session.token}" }
    end

    describe "GET /api/ping" do
      it "returns 200 and JSON status ok" do
        get api_ping_path, headers: auth_headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("ok")
        expect(json).to have_key("timestamp")
      end
    end
  end

  context "when not authenticated" do
    describe "GET /api/ping" do
      it "returns 401 Unauthorized" do
        get api_ping_path
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
