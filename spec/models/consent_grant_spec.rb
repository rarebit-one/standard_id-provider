require "rails_helper"

RSpec.describe StandardId::Provider::ConsentGrant, type: :model do
  let(:account) { Account.create!(name: "Test User", email: "test@example.com") }
  let(:client) { StandardId::ClientApplication.create!(name: "App", owner: account, redirect_uris: ["https://example.com/callback"]) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:scopes) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:client_application) }
  end

  describe ".active" do
    it "returns only non-revoked grants" do
      active = described_class.create!(account: account, client_application: client, scopes: "openid")
      revoked = described_class.create!(account: account, client_application: client, scopes: "openid", revoked_at: Time.current)

      expect(described_class.active).to include(active)
      expect(described_class.active).not_to include(revoked)
    end
  end

  describe "#revoke!" do
    it "sets revoked_at" do
      grant = described_class.create!(account: account, client_application: client, scopes: "openid profile")
      expect(grant.revoked_at).to be_nil

      grant.revoke!
      expect(grant.revoked_at).to be_present
    end
  end

  describe "#covers_scopes?" do
    let(:grant) { described_class.create!(account: account, client_application: client, scopes: "openid profile email") }

    it "returns true when all requested scopes are covered" do
      expect(grant.covers_scopes?(%w[openid profile])).to be true
    end

    it "returns false when requested scopes exceed granted scopes" do
      expect(grant.covers_scopes?(%w[openid admin])).to be false
    end
  end

  describe "granted_at auto-set" do
    it "sets granted_at on create" do
      grant = described_class.create!(account: account, client_application: client, scopes: "openid")
      expect(grant.granted_at).to be_present
    end
  end
end
