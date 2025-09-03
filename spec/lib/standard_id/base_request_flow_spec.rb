require "rails_helper"

RSpec.describe StandardId::Oauth::BaseRequestFlow do
  describe "class configuration API" do
    let(:flow_class) { Class.new(described_class) }

    it "defaults to no expected or permitted params" do
      expect(flow_class.expected_params).to eq([])
      expect(flow_class.permitted_params).to eq([])
    end

    it "collects expected params (symbolized, unique)" do
      flow_class.expect_params(:client_id, "password", :client_id)
      expect(flow_class.expected_params).to match_array([:client_id, :password])
    end

    it "collects permitted params merged with expected (unique)" do
      flow_class.expect_params(:client_id, :password)
      flow_class.permit_params("audience", :scope, :client_id)
      # permitted_params returns (expected + permitted + extra_permitted_keys).uniq
      expect(flow_class.permitted_params).to match_array([
        :client_id, :password, :audience, :scope
      ])
    end

    it "allows subclasses to append extra permitted keys" do
      subclass = Class.new(described_class) do
        class << self
          def extra_permitted_keys
            [:foo, :bar]
          end
        end
      end

      subclass.expect_params(:a)
      subclass.permit_params(:b)
      expect(subclass.permitted_params).to match_array([:a, :b, :foo, :bar])
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
  end
end
