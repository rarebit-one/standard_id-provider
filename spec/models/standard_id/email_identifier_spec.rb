require "rails_helper"

module StandardId
  RSpec.describe EmailIdentifier, type: :model do
    let(:account) { Account.create!(name: "Test User", email: "account@example.com") }

    it { is_expected.to be_a(Identifier) }
    it { is_expected.to belong_to(:account) }

    describe "validations" do
      it "validates email format" do
        subject = EmailIdentifier.new(value: "invalid-email", account: account)
        expect(subject).not_to be_valid
        expect(subject.errors[:value]).to be_present

        subject.value = "user@example.com"
        subject.valid?
        expect(subject.errors[:value]).to be_empty
      end
    end
  end
end
