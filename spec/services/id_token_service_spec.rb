require "rails_helper"

RSpec.describe StandardId::Provider::IdTokenService do
  describe ".generate" do
    let(:subject_id) { "user-123" }
    let(:client_id) { "client-abc" }

    it "generates a valid JWT" do
      token = described_class.generate(subject_id: subject_id, client_id: client_id)

      payload = StandardId::JwtService.decode(token)
      expect(payload[:sub]).to eq(subject_id)
      expect(payload[:aud]).to eq(client_id)
    end

    it "includes nonce when provided" do
      token = described_class.generate(subject_id: subject_id, client_id: client_id, nonce: "test-nonce")

      payload = StandardId::JwtService.decode(token)
      expect(payload[:nonce]).to eq("test-nonce")
    end

    it "computes at_hash from access token" do
      access_token = "some-access-token"
      token = described_class.generate(subject_id: subject_id, client_id: client_id, access_token: access_token)

      payload = StandardId::JwtService.decode(token)
      expect(payload[:at_hash]).to be_present
    end

    it "computes c_hash from authorization code" do
      code = "some-authorization-code"
      token = described_class.generate(subject_id: subject_id, client_id: client_id, authorization_code: code)

      payload = StandardId::JwtService.decode(token)
      expect(payload[:c_hash]).to be_present
    end

    it "includes auth_time when provided" do
      auth_time = Time.current
      token = described_class.generate(subject_id: subject_id, client_id: client_id, auth_time: auth_time)

      payload = StandardId::JwtService.decode(token)
      expect(payload[:auth_time]).to eq(auth_time.to_i)
    end

    it "merges extra claims" do
      token = described_class.generate(subject_id: subject_id, client_id: client_id, extra_claims: { email: "user@example.com" })

      payload = StandardId::JwtService.decode(token)
      expect(payload[:email]).to eq("user@example.com")
    end

    it "excludes nil optional fields" do
      token = described_class.generate(subject_id: subject_id, client_id: client_id)

      payload = StandardId::JwtService.decode(token)
      expect(payload).not_to have_key(:nonce)
      expect(payload).not_to have_key(:at_hash)
      expect(payload).not_to have_key(:auth_time)
    end
  end
end
