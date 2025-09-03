require "rails_helper"

RSpec.describe "StandardId::Api::Oauth::TokensController", type: :request do
  # routes { StandardId::ApiEngine.routes }

  # let(:path) { "/api/oauth/token" }
  let(:path) { api_standard_id_api.oauth_token_path }

  describe "POST /api/oauth/token" do
    describe "error handling" do
      it "returns error when grant_type is missing" do
        post path, params: {}, as: :json

        expect(response).to have_http_status(:bad_request)
        body = JSON.parse(response.body)
        expect(body["error"]).to eq("invalid_request")
        expect(body["error_description"]).to eq("The grant_type parameter is required")
      end

      it "returns error for unsupported grant_type" do
        post path, params: { grant_type: "unsupported_grant" }, as: :json

        expect(response).to have_http_status(:bad_request)
        body = JSON.parse(response.body)
        expect(body["error"]).to eq("unsupported_grant_type")
        expect(body["error_description"]).to eq("Unsupported grant_type: unsupported_grant")
      end

      it "validates JSON content type" do
        post path, params: {}, headers: { "CONTENT_TYPE" => "application/x-www-form-urlencoded" }

        expect(response).to have_http_status(:bad_request)
        body = JSON.parse(response.body)
        expect(body["error"]).to eq("invalid_request")
        expect(body["error_description"]).to eq("Content-Type must be application/json or application/*+json")
      end

      it "accepts vendor-specific JSON content types" do
        post path, params: {}, headers: { "CONTENT_TYPE" => "application/vnd.api+json" }

        expect(response).to have_http_status(:bad_request)
        body = JSON.parse(response.body)
        expect(body["error"]).to eq("invalid_request")
        expect(body["error_description"]).to eq("The grant_type parameter is required")
      end
    end

    # describe "grant type validation" do
    #   it "recognizes client_credentials as valid grant type" do
    #     post path, params: { grant_type: "client_credentials" }, as: :json

    #     expect(response).to have_http_status(:bad_request)
    #     # Should fail on missing parameters, not unsupported grant type
    #     expect(response.body).not_to include("unsupported_grant_type")
    #   end

    #   it "recognizes authorization_code as valid grant type" do
    #     post path, params: { grant_type: "authorization_code" }, as: :json

    #     expect(response).to have_http_status(:bad_request)
    #     # Should fail on missing parameters, not unsupported grant type
    #     expect(response.body).not_to include("unsupported_grant_type")
    #   end

    #   it "recognizes password as valid grant type" do
    #     post path, params: { grant_type: "password" }, as: :json

    #     expect(response).to have_http_status(:bad_request)
    #     # Should fail on missing parameters, not unsupported grant type
    #     expect(response.body).not_to include("unsupported_grant_type")
    #   end
    # end

    # describe "response headers" do
    #   it "sets cache headers on error responses" do
    #     post path, params: { grant_type: "invalid" }, as: :json

    #     expect(response.headers["Cache-Control"]).to eq("no-cache")
    #   end

    #   it "sets cache headers on missing grant_type" do
    #     post path, params: {}, as: :json

    #     expect(response.headers["Cache-Control"]).to eq("no-cache")
    #   end
    # end

    # describe "OAuth error format" do
    #   it "returns proper OAuth error structure" do
    #     post path, params: { grant_type: "invalid" }, as: :json

    #     expect(response).to have_http_status(:bad_request)
    #     body = JSON.parse(response.body)
    #     expect(body).to have_key("error")
    #     expect(body).to have_key("error_description")
    #     expect(body["error"]).to be_a(String)
    #     expect(body["error_description"]).to be_a(String)
    #   end

    #   it "uses standard OAuth error codes" do
    #     post path, params: {}, as: :json
    #     body = JSON.parse(response.body)
    #     expect(body["error"]).to eq("invalid_request")

    #     post path, params: { grant_type: "unsupported" }, as: :json
    #     body = JSON.parse(response.body)
    #     expect(body["error"]).to eq("unsupported_grant_type")
    #   end
    # end

    # describe "controller inheritance" do
    #   it "inherits JSON content-type validation from Api::BaseController" do
    #     post path, params: {}, headers: { "CONTENT_TYPE" => "text/plain" }

    #     expect(response).to have_http_status(:bad_request)
    #     body = JSON.parse(response.body)
    #     expect(body["error"]).to eq("invalid_request")
    #     expect(body["error_description"]).to include("Content-Type")
    #   end

    #   it "inherits cache headers from Api::BaseController" do
    #     post path, params: {}, as: :json

    #     expect(response.headers["Cache-Control"]).to eq("no-cache")
    #   end
    # end
  end
end
