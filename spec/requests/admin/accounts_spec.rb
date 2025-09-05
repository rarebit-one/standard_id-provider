require "rails_helper"

RSpec.describe "Admin::AccountsController", type: :request do
  describe "GET /admin/accounts" do
    it "returns a 200 and renders placeholder text" do
      get "/admin/accounts"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Admin Accounts - Not implemented yet")
    end
  end

  describe "GET /admin/accounts/:id" do
    it "returns a 200 and renders placeholder text for details" do
      account = Account.create!(name: "Request Spec User", email: "requestspec@example.com")

      get "/admin/accounts/#{account.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Admin Account Details - Not implemented yet")
    end
  end
end
