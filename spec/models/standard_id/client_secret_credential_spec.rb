require "rails_helper"

module StandardId
  RSpec.describe ClientSecretCredential, type: :model do
    let(:account) { Account.create!(name: "Service Owner", email: "owner@example.com") }
    let(:identifier) { EmailIdentifier.create!(account:, value: "owner@example.com") }
    let(:client) { ClientApplication.create!(owner: account, name: "Test Client", redirect_uris: "https://example.com/callback") }

    def build_with_linked_credential(attrs = {})
      cc = described_class.create!({ name: "my-service", client_secret: "topsecret", client_application: client }.merge(attrs))
      Credential.create!(identifier:, credentialable: cc)
      cc
    end

    it { is_expected.to have_one(:credential) }
    it { is_expected.to delegate_method(:account).to(:credential) }

    it "uses has_secure_password for client_secret" do
      cc = build_with_linked_credential
      expect(cc.client_secret_digest).to be_present
      expect(cc.authenticate_client_secret("topsecret")).to be_truthy
      expect(cc.authenticate_client_secret("wrong")).to be_falsey
    end

    it "sets client_id from client on create" do
      cc = build_with_linked_credential
      expect(cc.client_id).to eq(client.client_id)
    end

    it "validates presence of client_id" do
      cc = described_class.new(name: "service-2", client_secret: "topsecret", client_application: client)
      # Bypass the callback that sets client_id
      cc.define_singleton_method(:set_client_id_from_client) { }
      cc.client_id = nil
      expect(cc.valid?).to be false
      expect(cc.errors[:client_id]).to include("can't be blank")
    end

    it "default active scope returns only active and not revoked" do
      active_cc = build_with_linked_credential(name: "active")
      active_cc.save!

      revoked_cc = build_with_linked_credential(name: "revoked")
      revoked_cc.save!
      revoked_cc.revoke!

      expect(described_class.active).to include(active_cc)
      expect(described_class.active).not_to include(revoked_cc)
    end

    it "revoke! marks as inactive and sets revoked_at" do
      cc = build_with_linked_credential
      cc.save!
      expect(cc.active?).to be true

      cc.revoke!
      cc.reload
      expect(cc.active?).to be false
      expect(cc.revoked_at).to be_present
    end

    describe "#scopes_array" do
      it "returns empty array when scopes is nil" do
        cc = build_with_linked_credential(scopes: nil)
        expect(cc.scopes_array).to eq([])
      end

      it "splits space-delimited scopes and strips blanks" do
        cc = build_with_linked_credential(scopes: "read:users  write:users   admin ")
        expect(cc.scopes_array).to eq(["read:users", "write:users", "admin"])
      end
    end
  end
end
