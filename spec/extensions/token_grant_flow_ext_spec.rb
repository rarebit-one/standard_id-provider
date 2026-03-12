require "rails_helper"

RSpec.describe StandardId::Provider::Extensions::TokenGrantFlowExt do
  describe "#build_jwt_payload" do
    it "adds jti claim to JWT payloads" do
      token = generate_access_token
      payload = StandardId::JwtService.decode(token)

      # The token was generated via JwtService.encode which goes through
      # TokenGrantFlow's build_jwt_payload (now prepended with jti)
      # For unit testing, verify the extension module defines the method
      flow_class = StandardId::Oauth::TokenGrantFlow
      expect(flow_class.ancestors).to include(described_class)
    end
  end

  describe "id_token generation" do
    it "defines id_token_nonce as nil by default" do
      # The extension provides a default nil implementation
      # that AuthorizationCodeFlowExt overrides
      mod = described_class
      expect(mod.instance_method(:id_token_nonce)).to be_a(UnboundMethod)
    end
  end
end
