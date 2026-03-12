require "rails_helper"
require "active_support/testing/time_helpers"

module StandardId
  RSpec.describe PasswordCredential, type: :model do
    include ActiveSupport::Testing::TimeHelpers

    it_behaves_like "a credentialable"

    let(:account) { Account.create!(name: "Test User", email: "account@example.com") }
    let(:identifier) { EmailIdentifier.create!(account: account, value: "user@example.com") }

    subject { described_class.new(login: "user@example.com", password: "password123") }

    it { is_expected.to have_one(:credential) }
    it { is_expected.to delegate_method(:account).to(:credential) }

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

    describe "remember_me token generation" do
      let!(:credential) do
        described_class.create!(
          login: "user@example.com",
          password: "password123",
          password_confirmation: "password123"
        )
      end

      it "generates a token and finds record via find_by_token_for" do
        token = credential.generate_token_for(:remember_me)
        expect(token).to be_a(String)
        expect(token.length).to be > 10

        found = described_class.find_by_token_for(:remember_me, token)
        expect(found).to eq(credential)
      end

      it "invalidates the token when password changes" do
        token = credential.generate_token_for(:remember_me)
        expect(described_class.find_by_token_for(:remember_me, token)).to eq(credential)

        # Changing password updates password_digest, which our token depends on
        credential.update!(password: "newpassword123", password_confirmation: "newpassword123")

        expect(described_class.find_by_token_for(:remember_me, token)).to be_nil

        new_token = credential.generate_token_for(:remember_me)
        expect(described_class.find_by_token_for(:remember_me, new_token)).to eq(credential)
      end

      it "expires the token after the configured duration" do
        freeze_time do
          token = credential.generate_token_for(:remember_me)
          expect(described_class.find_by_token_for(:remember_me, token)).to eq(credential)

          travel 30.days + 1.second
          expect(described_class.find_by_token_for(:remember_me, token)).to be_nil
        end
      end
    end
  end
end
