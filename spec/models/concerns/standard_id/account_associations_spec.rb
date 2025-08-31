require "rails_helper"

RSpec.describe StandardId::AccountAssociations, type: :model do
  let(:account) { Account.create!(name: "Test User", email: "account@example.com") }

  describe "associations" do
    it { expect(account).to have_many(:identifiers) }
    it { expect(account).to have_many(:credentials).through(:identifiers) }
  end
end
