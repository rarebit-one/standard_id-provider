require "rails_helper"

module StandardId
  RSpec.describe Identifier, type: :model do
    let(:account) { Account.create!(name: "Test User", email: "account@example.com") }

    it { is_expected.to belong_to(:account) }

    describe "validations" do
      it { should validate_presence_of(:value) }
    end

    describe "#verified?" do
      it "returns true when verified_at is present" do
        identifier = EmailIdentifier.new(verified_at: Time.current)
        expect(identifier).to be_verified
      end

      it "returns false when verified_at is nil" do
        identifier = EmailIdentifier.new(verified_at: nil)
        expect(identifier).not_to be_verified
      end
    end

    describe "#verify!" do
      it "sets verified_at to current time" do
        identifier = EmailIdentifier.new(account: account, value: "test@example.com")
        identifier.save!

        current_time = Time.current
        identifier.verify!
        expect(identifier.verified_at).to be_within(1.second).of(current_time)
      end
    end

    describe "#unverify!" do
      it "sets verified_at to nil" do
        identifier = EmailIdentifier.new(account: account, value: "test@example.com", verified_at: 1.day.ago)
        identifier.save!

        identifier.unverify!
        expect(identifier.verified_at).to be_nil
      end
    end
  end
end
