require "rails_helper"

RSpec.describe StandardId::ServiceSession, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:account) { Account.create!(name: "Test Service", email: "service@example.com") }

  describe "inheritance" do
    it "inherits from StandardId::Session" do
      expect(StandardId::ServiceSession.superclass).to eq(StandardId::Session)
    end
  end

  describe "validations" do
    it "validates presence of service_name" do
      session = StandardId::ServiceSession.new(account: account, service_name: "", service_version: "1.0.0")
      expect(session).not_to be_valid
      expect(session.errors[:service_name]).to include("can't be blank")
    end

    it "validates presence of service_version" do
      session = StandardId::ServiceSession.new(account: account, service_name: "api-gateway", service_version: "")
      expect(session).not_to be_valid
      expect(session.errors[:service_version]).to include("can't be blank")
    end
  end

  describe "instance methods" do
    let(:service_session) do
      StandardId::ServiceSession.create!(
        account: account,
        service_name: "payment-processor",
        service_version: "2.1.3",
        expires_at: 90.days.from_now
      )
    end

    describe "#display_name" do
      it "returns service-specific display name" do
        expect(service_session.display_name).to eq("payment-processor Service Session (v2.1.3)")
      end
    end

    describe "#service_info" do
      it "returns service information hash" do
        info = service_session.service_info
        expect(info[:name]).to eq('payment-processor')
        expect(info[:version]).to eq('2.1.3')
        expect(info[:type]).to eq('service')
      end
    end

    describe "#refresh!" do
      it "does not update any timestamps (no-op for service sessions)" do
        original_updated_at = service_session.updated_at
        travel_to 1.hour.from_now do
          service_session.refresh!
          expect(service_session.updated_at).to eq(original_updated_at)
        end
      end
    end

    describe "#stale?" do
      it "always returns false for service sessions" do
        expect(service_session.stale?).to be false
      end

      it "returns false even for old service sessions" do
        travel_to 30.days.from_now do
          expect(service_session.stale?).to be false
        end
      end
    end
  end

  describe "class methods" do
    describe ".default_expiry" do
      it "returns 90 days from now" do
        travel_to Time.current do
          expect(StandardId::ServiceSession.default_expiry).to eq(90.days.from_now)
        end
      end
    end
  end

  describe "session lifecycle" do
    let(:service_session) do
      StandardId::ServiceSession.create!(
        account: account,
        service_name: "notification-service",
        service_version: "1.5.0",
        expires_at: 90.days.from_now
      )
    end

    it "is active when created" do
      expect(service_session.active?).to be true
    end

    it "becomes inactive when revoked" do
      service_session.revoke!
      expect(service_session.active?).to be false
      expect(service_session.revoked?).to be true
    end

    it "becomes inactive when expired" do
      service_session.update!(expires_at: 1.day.ago)
      expect(service_session.active?).to be false
      expect(service_session.expired?).to be true
    end
  end

  describe "token generation" do
    it "generates a token on creation" do
      session = StandardId::ServiceSession.create!(
        account: account,
        service_name: "auth-service",
        service_version: "3.0.0",
        expires_at: 90.days.from_now
      )

      expect(session.token).to be_present
      expect(session.lookup_hash).to be_present
      expect(session.token_digest).to be_present
    end

    it "can be found by token" do
      session = StandardId::ServiceSession.create!(
        account: account,
        service_name: "data-processor",
        service_version: "1.2.0",
        expires_at: 90.days.from_now
      )

      found_session = StandardId::ServiceSession.lookup_by_token(session.token)
      expect(found_session).to eq(session)
    end
  end

  describe "scopes" do
    let!(:active_session) do
      StandardId::ServiceSession.create!(
        account: account,
        service_name: "active-service",
        service_version: "1.0.0",
        expires_at: 30.days.from_now
      )
    end

    let!(:expired_session) do
      StandardId::ServiceSession.create!(
        account: account,
        service_name: "expired-service",
        service_version: "1.0.0",
        expires_at: 1.day.ago
      )
    end

    let!(:revoked_session) do
      session = StandardId::ServiceSession.create!(
        account: account,
        service_name: "revoked-service",
        service_version: "1.0.0",
        expires_at: 30.days.from_now
      )
      session.revoke!
      session
    end

    it "includes active sessions in active scope" do
      expect(StandardId::ServiceSession.active).to include(active_session)
      expect(StandardId::ServiceSession.active).not_to include(expired_session)
      expect(StandardId::ServiceSession.active).not_to include(revoked_session)
    end

    it "includes expired sessions in expired scope" do
      expect(StandardId::ServiceSession.expired).to include(expired_session)
      expect(StandardId::ServiceSession.expired).not_to include(active_session)
    end

    it "includes revoked sessions in revoked scope" do
      expect(StandardId::ServiceSession.revoked).to include(revoked_session)
      expect(StandardId::ServiceSession.revoked).not_to include(active_session)
      expect(StandardId::ServiceSession.revoked).not_to include(expired_session)
    end
  end
end
