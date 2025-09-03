require "rails_helper"

RSpec.describe StandardId::Oauth::BaseFlow do
  describe "class configuration API" do
    let(:flow_class) { Class.new(described_class) }

    it "defaults to no expected params and only :grant_type permitted" do
      expect(flow_class.expected_params).to eq([])
      expect(flow_class.permitted_params).to eq([:grant_type])
    end

    it "collects expected params (symbolized, unique)" do
      flow_class.expect_params(:client_id, "password", :client_id)
      expect(flow_class.expected_params).to match_array([:client_id, :password])
    end

    it "collects permitted params merged with expected and :grant_type (unique)" do
      flow_class.expect_params(:client_id, :password)
      flow_class.permit_params("audience", :scope, :client_id)
      # permitted_params returns (expected + permitted + [:grant_type]).uniq
      expect(flow_class.permitted_params).to match_array([
        :client_id, :password, :audience, :scope, :grant_type
      ])
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
  end
end
