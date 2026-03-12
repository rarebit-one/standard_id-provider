require "rails_helper"

RSpec.describe StandardId::Provider::RevokedToken, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:jti) }

    it "validates uniqueness of jti" do
      described_class.create!(jti: "unique-jti", revoked_at: Time.current, expires_at: 1.day.from_now)
      duplicate = described_class.new(jti: "unique-jti", revoked_at: Time.current, expires_at: 1.day.from_now)
      expect(duplicate).not_to be_valid
    end
  end

  describe ".revoke!" do
    it "creates a revoked token record" do
      expect {
        described_class.revoke!(jti: "test-jti", client_id: "client-1", token_type: "access_token", expires_at: 1.hour.from_now)
      }.to change(described_class, :count).by(1)
    end

    it "is idempotent for duplicate jti" do
      described_class.revoke!(jti: "dup-jti", expires_at: 1.hour.from_now)
      expect {
        described_class.revoke!(jti: "dup-jti", expires_at: 1.hour.from_now)
      }.not_to change(described_class, :count)
    end
  end

  describe ".revoked?" do
    it "returns true for revoked jti" do
      described_class.revoke!(jti: "revoked-jti", expires_at: 1.hour.from_now)
      expect(described_class.revoked?("revoked-jti")).to be true
    end

    it "returns false for unknown jti" do
      expect(described_class.revoked?("unknown-jti")).to be false
    end
  end

  describe ".cleanup_expired!" do
    it "removes expired records" do
      described_class.create!(jti: "expired", revoked_at: 2.days.ago, expires_at: 1.day.ago)
      described_class.create!(jti: "active", revoked_at: Time.current, expires_at: 1.day.from_now)

      described_class.cleanup_expired!

      expect(described_class.where(jti: "expired")).not_to exist
      expect(described_class.where(jti: "active")).to exist
    end
  end
end
