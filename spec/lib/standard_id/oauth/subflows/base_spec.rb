require "rails_helper"

RSpec.describe StandardId::Oauth::Subflows::Base do
  let(:params) { { client_id: "test_client", scope: "read" } }
  subject { described_class.new(**params) }

  describe "#initialize" do
    it "stores params" do
      expect(subject.send(:params)).to eq(params)
    end
  end

  describe "#call" do
    it "raises NotImplementedError" do
      expect { subject.call }.to raise_error(
        NotImplementedError,
        "Subclasses must implement #call"
      )
    end
  end
end
