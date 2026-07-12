require "rails_helper"

# Introspection (RFC 7662) and revocation (RFC 7009) are credential-guessable
# endpoints; these specs cover the per-IP rate_limit added in front of client
# authentication.
RSpec.describe "Rate limiting: Provider token endpoints", type: :request do
  let(:client_app) { create_oauth_client }
  let(:credential) { client_app.last }
  let(:auth_headers) { basic_auth_header(credential.client_id, "test-client-secret") }
  let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

  before do
    # Real store so the native rate_limit actually fires (test cache is inert).
    allow(StandardId::RateLimitHandling::RATE_LIMIT_STORE)
      .to receive(:increment) { |name, amount, **opts| memory_store.increment(name, amount, **opts) }
  end

  describe "POST /api/provider/introspect" do
    it "returns 429 once the per-IP limit is exceeded" do
      limit = (ENV["RATE_LIMIT_INTROSPECT_PER_IP"] || 30).to_i

      limit.times { post "/api/provider/introspect", params: { token: "x" }, headers: auth_headers }

      post "/api/provider/introspect", params: { token: "x" }, headers: auth_headers
      expect(response).to have_http_status(:too_many_requests)
      expect(json_body["error"]).to eq("rate_limit_exceeded")
      expect(response.headers["Retry-After"]).to eq(15.minutes.to_i.to_s)
    end
  end

  describe "POST /api/provider/revoke" do
    it "returns 429 once the per-IP limit is exceeded" do
      limit = (ENV["RATE_LIMIT_REVOKE_PER_IP"] || 30).to_i

      limit.times { post "/api/provider/revoke", params: { token: "x" }, headers: auth_headers }

      post "/api/provider/revoke", params: { token: "x" }, headers: auth_headers
      expect(response).to have_http_status(:too_many_requests)
      expect(json_body["error"]).to eq("rate_limit_exceeded")
    end
  end
end
