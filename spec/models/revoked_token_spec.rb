require "rails_helper"

RSpec.describe StandardId::Provider::RevokedToken, type: :model do
  describe "validations" do
    subject { described_class.new(jti: "unique-jti", revoked_at: Time.current, expires_at: 1.day.from_now) }

    it { is_expected.to validate_presence_of(:jti) }
    it { is_expected.to validate_uniqueness_of(:jti) }
  end

  describe ".revoke!" do
    it "creates a revoked token record" do
      expect {
        described_class.revoke!(jti: "test-jti-123")
      }.to change(described_class, :count).by(1)
    end

    it "is idempotent for duplicate JTIs" do
      described_class.revoke!(jti: "dup-jti")

      expect {
        described_class.revoke!(jti: "dup-jti")
      }.not_to change(described_class, :count)
    end
  end

  describe ".revoked?" do
    it "returns true for revoked tokens" do
      described_class.revoke!(jti: "revoked-jti")

      expect(described_class.revoked?("revoked-jti")).to be true
    end

    it "returns false for non-revoked tokens" do
      expect(described_class.revoked?("unknown-jti")).to be false
    end
  end

  describe ".cleanup_expired!" do
    it "removes expired records" do
      described_class.revoke!(jti: "expired-jti", expires_at: 1.day.ago)

      expect {
        described_class.cleanup_expired!
      }.to change(described_class, :count).by(-1)
    end
  end
end
