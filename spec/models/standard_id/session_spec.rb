require "rails_helper"

RSpec.describe StandardId::Session, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:account) { Account.create!(name: "Test User", email: "test@example.com") }

  describe "associations" do
    it { should belong_to(:account) }
  end

  describe "scopes" do
    let!(:active_session) do
      StandardId::BrowserSession.create!(
        account:,
        user_agent: "Chrome/91.0",
        expires_at: 1.hour.from_now,
        revoked_at: nil
      )
    end

    let!(:expired_session) do
      StandardId::BrowserSession.create!(
        account:,
        user_agent: "Chrome/91.0",
        expires_at: 1.hour.ago,
        revoked_at: nil
      )
    end

    let!(:revoked_session) do
      StandardId::BrowserSession.create!(
        account:,
        user_agent: "Chrome/91.0",
        expires_at: 1.hour.from_now,
        revoked_at: 1.minute.ago
      )
    end

    describe ".active" do
      it "returns only non-revoked, non-expired sessions" do
        expect(StandardId::Session.active).to contain_exactly(active_session)
      end
    end

    describe ".expired" do
      it "returns only expired sessions" do
        expect(StandardId::Session.expired).to contain_exactly(expired_session)
      end
    end

    describe ".revoked" do
      it "returns only revoked sessions" do
        expect(StandardId::Session.revoked).to contain_exactly(revoked_session)
      end
    end
  end

  describe "instance methods" do
    let(:session) do
      StandardId::BrowserSession.create!(
        account:,
        user_agent: "Chrome/91.0",
        expires_at: 1.hour.from_now,
        revoked_at: nil
      )
    end

    describe "#active?" do
      it "returns true for non-revoked, non-expired sessions" do
        expect(session.active?).to be true
      end

      it "returns false for expired sessions" do
        session.update!(expires_at: 1.hour.ago)
        expect(session.active?).to be false
      end

      it "returns false for revoked sessions" do
        session.update!(revoked_at: Time.current)
        expect(session.active?).to be false
      end
    end

    describe "#expired?" do
      it "returns false for non-expired sessions" do
        expect(session.expired?).to be false
      end

      it "returns true for expired sessions" do
        session.update!(expires_at: 1.hour.ago)
        expect(session.expired?).to be true
      end
    end

    describe "#revoked?" do
      it "returns false for non-revoked sessions" do
        expect(session.revoked?).to be false
      end

      it "returns true for revoked sessions" do
        session.update!(revoked_at: Time.current)
        expect(session.revoked?).to be true
      end
    end

    describe "#revoke!" do
      it "sets revoked_at to current time" do
        travel_to Time.current do
          session.revoke!
          expect(session.revoked_at).to eq(Time.current)
        end
      end
    end
  end
end
