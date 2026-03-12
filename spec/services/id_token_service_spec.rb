require "rails_helper"

RSpec.describe StandardId::Provider::IdTokenService do
  describe ".generate" do
    it "returns a signed JWT" do
      token = described_class.generate(subject_id: "user-1", client_id: "client-1")
      payload = StandardId::JwtService.decode(token)

      expect(payload[:sub]).to eq("user-1")
      expect(payload[:aud]).to eq("client-1")
      expect(payload[:exp]).to be_present
      expect(payload[:iat]).to be_present
    end

    it "includes nonce when provided" do
      token = described_class.generate(subject_id: "user-1", client_id: "client-1", nonce: "abc123")
      payload = StandardId::JwtService.decode(token)

      expect(payload[:nonce]).to eq("abc123")
    end

    it "excludes nonce when not provided" do
      token = described_class.generate(subject_id: "user-1", client_id: "client-1")
      payload = StandardId::JwtService.decode(token)

      expect(payload).not_to have_key(:nonce)
    end

    it "includes at_hash when access_token is provided" do
      token = described_class.generate(subject_id: "user-1", client_id: "client-1", access_token: "some-access-token")
      payload = StandardId::JwtService.decode(token)

      expect(payload[:at_hash]).to be_present
    end

    it "includes c_hash when authorization_code is provided" do
      token = described_class.generate(subject_id: "user-1", client_id: "client-1", authorization_code: "some-code")
      payload = StandardId::JwtService.decode(token)

      expect(payload[:c_hash]).to be_present
    end

    it "includes auth_time when provided" do
      auth_time = Time.current
      token = described_class.generate(subject_id: "user-1", client_id: "client-1", auth_time: auth_time)
      payload = StandardId::JwtService.decode(token)

      expect(payload[:auth_time]).to eq(auth_time.to_i)
    end

    it "merges extra_claims" do
      token = described_class.generate(subject_id: "user-1", client_id: "client-1", extra_claims: { email: "user@example.com" })
      payload = StandardId::JwtService.decode(token)

      expect(payload[:email]).to eq("user@example.com")
    end
  end
end
