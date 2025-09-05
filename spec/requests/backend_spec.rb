require "rails_helper"

RSpec.describe "Admin", type: :request do
  let(:account) { Account.create!(email: "test@example.com", name: "Test User") }
  let(:browser_session) { StandardId::BrowserSession.create!(account: account, ip_address: "127.0.0.1", user_agent: "Test", expires_at: 30.days.from_now) }

  context "when authenticated" do
    before { post util_session_path, params: { session_token: browser_session.token } }

    describe "GET /admin" do
      it "returns 200 and renders the dashboard" do
        get admin_root_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Admin Dashboard")
      end
    end
  end

  context "when not authenticated" do
    describe "GET /admin" do
      it "returns 302 and redirects to login page" do
        get admin_root_path
        expect(response).to have_http_status(302)
        expect(response.location).to include(standard_id_web.login_path)
      end
    end
  end
end
