require "rails_helper"

module StandardId
  RSpec.describe PhoneNumberIdentifier, type: :model do
    let(:account) { Account.create!(name: "Test User", email: "account@example.com") }

    it { is_expected.to be_a(Identifier) }
    it { is_expected.to belong_to(:account) }

    describe "validations" do
      it "validates phone number format" do
        subject = PhoneNumberIdentifier.new(value: "invalid-phone", account: account)
        expect(subject).not_to be_valid
        expect(subject.errors[:value]).to be_present

        subject.value = "+1234567890"
        subject.valid?
        expect(subject.errors[:value]).to be_empty
      end
    end
  end
end
