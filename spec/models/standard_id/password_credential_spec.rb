require "rails_helper"

module StandardId
  RSpec.describe PasswordCredential, type: :model do
    it_behaves_like "a credentialable"

    let(:account) { Account.create!(name: "Test User", email: "account@example.com") }
    let(:identifier) { EmailIdentifier.create!(account: account, value: "user@example.com") }

    subject { described_class.new(login: "user@example.com", password: "password123") }

    it { is_expected.to have_secure_password }

    it { is_expected.to validate_presence_of(:login) }
    it "validates uniqueness of login" do
      subject.save!
      duplicate = described_class.new(login: "user@example.com", password: "password456")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:login]).to include("has already been taken")
    end

    it { is_expected.to validate_length_of(:password).is_at_least(8) }
    it { is_expected.to validate_confirmation_of(:password) }
  end
end
