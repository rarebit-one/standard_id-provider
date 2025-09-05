require "rails_helper"

RSpec.describe StandardId::Web::ResetPassword::StartController, type: :controller do
  routes { StandardId::WebEngine.routes }

  describe "GET #show" do
    it "renders the password reset form" do
      get :show
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create" do
    let(:account) { Account.create!(email: "user@example.com", name: "Test User") }
    let(:email) { "user@example.com" }
    let!(:identifier) { StandardId::EmailIdentifier.create!(account: account, value: email) }
    let!(:password_credential) { StandardId::PasswordCredential.create!(login: email, password: "password123") }
    let!(:credential) { StandardId::Credential.create!(credentialable: password_credential, identifier: identifier) }

    context "with valid email" do
      it "sends reset instructions and redirects to login" do
        allow(Rails.logger).to receive(:info)
        
        post :create, params: { email: email }
        
        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to eq("If an account with that email exists, we've sent password reset instructions.")
      end
    end

    context "with non-existent email" do
      it "shows success message without revealing email doesn't exist" do
        post :create, params: { email: "nonexistent@example.com" }
        
        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to eq("If an account with that email exists, we've sent password reset instructions.")
      end
    end

    context "with blank email" do
      it "shows error and re-renders form" do
        post :create, params: { email: "" }
        
        expect(response).to have_http_status(:unprocessable_content)
        expect(flash[:alert]).to eq("Please enter your email address")
      end
    end

    context "with whitespace-only email" do
      it "shows error and re-renders form" do
        post :create, params: { email: "   " }
        
        expect(response).to have_http_status(:unprocessable_content)
        expect(flash[:alert]).to eq("Please enter your email address")
      end
    end
  end
end
