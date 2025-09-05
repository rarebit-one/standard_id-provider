require "rails_helper"

RSpec.describe "Admin::AccountsController", type: :request do
  let(:account) { Account.create!(email: "test@example.com", name: "Test User") }
  let(:browser_session) { StandardId::BrowserSession.create!(account: account, ip_address: "127.0.0.1", user_agent: "Test", expires_at: 30.days.from_now) }

  before { post util_session_path, params: { session_token: browser_session.token } }

  describe "GET /admin/accounts" do
    it "returns a 200 and renders the accounts page" do
      get "/admin/accounts"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Accounts")
    end
  end

  describe "GET /admin/accounts/:id" do
    it "returns a 200 and renders account details" do
      test_account = Account.create!(name: "Request Spec User", email: "requestspec@example.com")

      get "/admin/accounts/#{test_account.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Account Details")
    end
  end
end
