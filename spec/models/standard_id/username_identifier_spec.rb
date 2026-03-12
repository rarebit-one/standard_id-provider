require "rails_helper"

module StandardId
  RSpec.describe UsernameIdentifier, type: :model do
    let(:account) { Account.create!(name: "Test User", email: "account@example.com") }

    it { is_expected.to be_a(Identifier) }
    it { is_expected.to belong_to(:account) }

    describe "validations" do
      it "validates username format" do
        subject = UsernameIdentifier.new(value: "invalid-username!", account: account)
        expect(subject).not_to be_valid
        expect(subject.errors[:value]).to be_present

        subject.value = "valid_username123"
        subject.valid?
        expect(subject.errors[:value]).to be_empty
      end
    end
  end
end
