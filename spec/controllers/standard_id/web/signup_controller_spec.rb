require "rails_helper"

RSpec.describe StandardId::Web::SignupController, type: :controller do
  routes { StandardId::WebEngine.routes }

  describe "GET #show" do
    context "when not authenticated" do
      it "renders the signup page" do
        get :show, params: { redirect_uri: "/welcome" }

        expect(response).to have_http_status(:ok)
      end
    end

    context "when already authenticated" do
      it "redirects to after_authentication_url" do
        account = Account.create!(name: "Auth'd", email: "authd@example.com")
        allow(controller).to receive(:current_account).and_return(account)

        get :show

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to("/")
      end
    end
  end

  describe "POST #create" do
    context "when social signup connection is present" do
      it "redirects to social authorize URL with connection param" do
        # Provide default_client_id for building the URL
        StandardId.config.define_singleton_method(:default_client_id) { "web_client" }
        allow(controller).to receive(:callback_url).and_return("/auth/callback/google")

        post :create, params: { connection: "google-oauth2", redirect_uri: "/after" }

        expect(response).to have_http_status(:found)
        expect(response.location).to start_with("http://test.host/api/authorize?")
        expect(response.location).to include("connection=google-oauth2")
        expect(response.location).to include("client_id=web_client")
      end
    end

    context "when password signup is attempted" do
      it "creates account artifacts, signs in, and redirects on valid input" do
        # Stub SignupForm to avoid hitting validations/DB
        fake_account = instance_double("Account")
        form_double = instance_double("StandardId::Web::SignupForm", submit: true, account: fake_account)
        allow(StandardId::Web::SignupForm).to receive(:new).and_return(form_double)

        fake_session_manager = instance_double("StandardId::Web::SessionManager", sign_in_account: true)
        allow(controller).to receive(:session_manager).and_return(fake_session_manager)

        post :create, params: { signup: { email: "new@example.com", password: "s3cureP@ss", password_confirmation: "s3cureP@ss" }, redirect_uri: "/after" }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to("/after")
      end

      it "renders the form with error on invalid input" do
        errors = ActiveModel::Errors.new(Object.new)
        errors.add(:base, "Invalid input")
        form_double = instance_double("StandardId::Web::SignupForm", submit: false, errors: errors)
        allow(StandardId::Web::SignupForm).to receive(:new).and_return(form_double)

        post :create, params: { signup: { email: "bad", password: "short", password_confirmation: "mismatch" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
