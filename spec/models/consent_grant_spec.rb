require "rails_helper"

RSpec.describe StandardId::Provider::ConsentGrant, type: :model do
  let(:account) { Account.create!(name: "Test User", email: "test-#{SecureRandom.hex(4)}@example.com") }
  let(:client) { create_oauth_client.first }

  describe "validations" do
    it { is_expected.to validate_presence_of(:scopes) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:client_application) }
  end

  describe ".active" do
    it "excludes revoked grants" do
      grant = described_class.create!(account: account, client_application: client, scopes: "openid")
      grant.revoke!

      expect(described_class.active).not_to include(grant)
    end
  end

  describe "#revoke!" do
    it "sets revoked_at" do
      grant = described_class.create!(account: account, client_application: client, scopes: "openid")
      grant.revoke!

      expect(grant.revoked_at).to be_present
    end
  end

  describe "#covers_scopes?" do
    it "returns true when all requested scopes are covered" do
      grant = described_class.create!(account: account, client_application: client, scopes: "openid profile email")

      expect(grant.covers_scopes?(%w[openid profile])).to be true
    end

    it "returns false when some requested scopes are missing" do
      grant = described_class.create!(account: account, client_application: client, scopes: "openid")

      expect(grant.covers_scopes?(%w[openid profile])).to be false
    end
  end

  describe "granted_at" do
    it "is auto-set on create" do
      grant = described_class.create!(account: account, client_application: client, scopes: "openid")

      expect(grant.granted_at).to be_present
    end
  end
end
