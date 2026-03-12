require "rails_helper"

RSpec.describe StandardId::Oauth::TokenGrantFlow do
  describe "class configuration API (grant-specific)" do
    let(:flow_class) { Class.new(described_class) }

    it "includes :grant_type via extra_permitted_keys" do
      expect(flow_class.expected_params).to eq([])
      expect(flow_class.permitted_params).to eq([:grant_type])
    end

    it "merges :grant_type into permitted params along with subclass config" do
      flow_class.expect_params(:client_id)
      flow_class.permit_params(:scope)
      expect(flow_class.permitted_params).to match_array([:client_id, :scope, :grant_type])
    end
  end

  describe "instance API" do
    let(:request) { instance_double("ActionDispatch::Request") }

    it "exposes params and request readers from initialize" do
      params = { a: 1 }
      flow = described_class.new(params, request)
      expect(flow.params).to eq(params)
      expect(flow.request).to eq(request)
    end

    it "execute calls authenticate! then generate_token_response and returns its result" do
      flow_class = Class.new(described_class) do
        def authenticate!
          @authenticated = true
        end

        def generate_token_response
          raise "authenticate! not called" unless @authenticated
          { access_token: "token", token_type: "bearer" }
        end
      end

      flow = flow_class.new({}, request)
      result = flow.execute
      expect(result).to eq({ access_token: "token", token_type: "bearer" })
    end

    it "generates a token response with JWT and optional fields" do
      # Define a concrete flow to provide required abstract methods
      concrete = Class.new(described_class) do
        def authenticate!; end
        def subject_id; "sub-123"; end
        def client_id; "cid-abc"; end
        def token_scope; "read write"; end
        def grant_type; "password"; end
        def audience; params[:audience]; end
        def token_expiry; 30.minutes; end
        def supports_refresh_token?; true; end
        def generate_refresh_token; "rtoken"; end
      end

      params = { audience: "https://api" }
      flow = concrete.new(params, request)

      expect(StandardId::JwtService).to receive(:encode) do |payload, opts|
        expect(payload).to include(
          sub: "sub-123",
          client_id: "cid-abc",
          scope: "read write",
          grant_type: "password",
          aud: "https://api"
        )
        expect(opts).to include(expires_in: 30.minutes)
        "jwt-token"
      end

      result = flow.execute
      expect(result).to include(
        access_token: "jwt-token",
        token_type: "Bearer",
        expires_in: 30.minutes.to_i,
        scope: "read write",
        refresh_token: "rtoken"
      )
    end

    it "validates client secret via StandardId::ClientSecretCredential" do
      concrete = Class.new(described_class) do
        def authenticate!
          # call the private validator from within authenticate!
          validate_client_secret!("cid", "secret")
        end
      end

      creds_double = instance_double("StandardId::ClientSecretCredential", authenticate_client_secret: true)
      scope_double = double("scope", find_by: creds_double)
      allow(StandardId::ClientSecretCredential).to receive(:active).and_return(scope_double)

      # Stub JWT generation since execute will call generate_token_response afterwards
      allow_any_instance_of(concrete).to receive(:generate_token_response).and_return({ ok: true })

      flow = concrete.new({}, request)
      expect { flow.execute }.not_to raise_error
    end
  end
end
