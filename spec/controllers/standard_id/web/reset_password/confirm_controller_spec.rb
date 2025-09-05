require "rails_helper"

RSpec.describe StandardId::Web::ResetPassword::ConfirmController, type: :controller do
  routes { StandardId::WebEngine.routes }

  let(:account) { Account.create!(email: "user@example.com", name: "Test User") }
  let(:email) { "user@example.com" }
  let!(:identifier) { StandardId::EmailIdentifier.create!(account: account, value: email) }
  let!(:password_credential) { StandardId::PasswordCredential.create!(login: email, password: "oldpassword123") }
  let!(:credential) { StandardId::Credential.create!(credentialable: password_credential, identifier: identifier) }
  let(:valid_token) { password_credential.generate_token_for(:password_reset) }

  describe "GET #show" do
    context "with valid token" do
      it "renders the password reset form" do
        get :show, params: { token: valid_token }
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid token" do
      it "redirects to login with error message" do
        get :show, params: { token: "invalid_token" }
        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to eq("Invalid or expired password reset link")
      end
    end

    context "with no token" do
      it "redirects to login with error message" do
        get :show
        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to eq("Invalid or expired password reset link")
      end
    end
  end

  describe "PATCH #update" do
    context "with valid token and password" do
      let(:new_password) { "newpassword123" }

      it "updates password and redirects to login" do
        patch :update, params: {
          token: valid_token,
          password: new_password,
          password_confirmation: new_password
        }

        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to eq("Your password has been successfully reset. Please sign in with your new password.")

        # Verify password was actually changed
        password_credential.reload
        expect(password_credential.authenticate(new_password)).to be_truthy
        expect(password_credential.authenticate("oldpassword123")).to be_falsey
      end

      it "destroys all existing sessions for security" do
        # Create some sessions
        session1 = StandardId::BrowserSession.create!(account: account, expires_at: 1.hour.from_now, user_agent: "Chrome/91.0")
        session2 = StandardId::BrowserSession.create!(account: account, expires_at: 1.hour.from_now, user_agent: "Firefox/89.0")

        patch :update, params: {
          token: valid_token,
          password: new_password,
          password_confirmation: new_password
        }

        expect(StandardId::Session.where(account: account)).to be_empty
      end
    end

    context "with invalid token" do
      it "redirects to login with error message" do
        patch :update, params: {
          token: "invalid_token",
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }

        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to eq("Invalid or expired password reset link")
      end
    end

    context "with blank password" do
      it "shows error and re-renders form" do
        patch :update, params: {
          token: valid_token,
          password: "",
          password_confirmation: ""
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(flash[:alert]).to include("Password cannot be blank")
      end
    end

    context "with mismatched password confirmation" do
      it "shows error and re-renders form" do
        patch :update, params: {
          token: valid_token,
          password: "newpassword123",
          password_confirmation: "differentpassword"
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(flash[:alert]).to include("confirmation doesn't match")
      end
    end

    context "with password too short" do
      it "shows error and re-renders form" do
        patch :update, params: {
          token: valid_token,
          password: "short",
          password_confirmation: "short"
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(flash[:alert]).to include("Password must be at least 8 characters long")
      end
    end
  end
end
