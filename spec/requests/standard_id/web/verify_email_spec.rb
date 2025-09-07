require "rails_helper"

RSpec.describe "StandardId Web Verify Email", type: :request do
  describe "GET /verify_email/start" do
    it "renders the start page" do
      http_get "/verify_email/start"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("verify email start")
    end
  end

  describe "POST /verify_email/start" do
    it "creates a verification challenge and sends code" do
      sender = double("email_sender")
      expect(sender).to receive(:call).with("user@example.com", kind_of(String))
      allow(StandardId.config).to receive(:passwordless_email_sender).and_return(sender)

      http_post "/verify_email/start", params: { email: "user@example.com" }

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(standard_id_web.login_path)

      ch = StandardId::CodeChallenge.last
      expect(ch).to be_present
      expect(ch.realm).to eq("verification")
      expect(ch.channel).to eq("email")
      expect(ch.target).to eq("user@example.com")
      expect(ch).to be_active
    end

    it "returns unprocessable when email missing" do
      http_post "/verify_email/start", params: { email: "" }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /verify_email/confirm" do
    it "shows confirm page for valid code" do
      ch = StandardId::CodeChallenge.create!(
        realm: "verification", channel: "email", target: "user@example.com",
        code: "123456", expires_at: 10.minutes.from_now
      )

      http_get "/verify_email/confirm", params: { email: "user@example.com", code: "123456" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("verify email confirm")
    end

    it "redirects for invalid code" do
      http_get "/verify_email/confirm", params: { email: "user@example.com", code: "BAD" }
      expect(response).to redirect_to(standard_id_web.login_path)
      expect(flash[:alert]).to include("Invalid or expired")
    end
  end

  describe "PATCH /verify_email/confirm" do
    it "marks identifier verified and consumes challenge" do
      account = Account.create!(name: "User", email: "user@example.com")
      idf = StandardId::EmailIdentifier.create!(account: account, value: "user@example.com")
      ch = StandardId::CodeChallenge.create!(
        realm: "verification", channel: "email", target: "user@example.com",
        code: "999000", expires_at: 10.minutes.from_now
      )

      http_patch "/verify_email/confirm", params: { email: "user@example.com", code: "999000" }

      expect(response).to redirect_to(standard_id_web.login_path)
      expect(flash[:notice]).to include("email has been verified")

      expect(idf.reload).to be_verified
      expect(ch.reload).to be_used
    end

    it "redirects when invalid" do
      http_patch "/verify_email/confirm", params: { email: "user@example.com", code: "BAD" }
      expect(response).to redirect_to(standard_id_web.login_path)
      expect(flash[:alert]).to include("Invalid or expired")
    end
  end
end
