require "rails_helper"
require "ostruct"

RSpec.describe StandardId::Oauth::AuthorizationFlow do
  describe "class configuration API (authorization-specific)" do
    let(:flow_class) { Class.new(described_class) }

    it "includes :response_type via extra_permitted_keys" do
      expect(flow_class.permitted_params).to include(:response_type)
    end
  end

  describe "execution and validations" do
    let(:request) { instance_double("ActionDispatch::Request") }

    # Minimal concrete implementation to exercise base behavior
    let(:concrete_class) do
      Class.new(described_class) do
        def generate_authorization_response
          { ok: true, redirect_to: redirect_uri, state: state, scope: scope, audience: audience }
        end
      end
    end

    def build_flow(params)
      concrete_class.new(params, request)
    end

    it "raises when response_type is missing" do
      flow = build_flow({ client_id: "cid" })
      expect { flow.execute }.to raise_error(StandardId::InvalidRequestError, /response_type/)
    end

    it "raises when client_id is missing" do
      flow = build_flow({ response_type: "code" })
      expect { flow.execute }.to raise_error(StandardId::InvalidRequestError, /client_id/)
    end

    it "raises InvalidClientError when client is not found" do
      allow(StandardId::ClientSecretCredential).to receive_message_chain(:active, :find_by).and_return(nil)
      flow = build_flow({ response_type: "code", client_id: "none" })
      expect { flow.execute }.to raise_error(StandardId::InvalidClientError)
    end

    it "validates redirect_uri against client's allowed list" do
      cred = OpenStruct.new(redirect_uris: "https://a.example/cb https://b.example/ok", default_redirect_uri: "https://a.example/cb")
      allow(StandardId::ClientSecretCredential).to receive_message_chain(:active, :find_by).and_return(cred)

      # invalid
      flow = build_flow({ response_type: "code", client_id: "cid", redirect_uri: "https://evil.example/x" })
      expect { flow.execute }.to raise_error(StandardId::InvalidRequestError, /redirect_uri/)

      # valid
      flow2 = build_flow({ response_type: "code", client_id: "cid", redirect_uri: "https://b.example/ok" })
      expect(flow2.execute).to include(ok: true, redirect_to: "https://b.example/ok")
    end

    it "uses client's default_redirect_uri when redirect_uri not provided" do
      cred = OpenStruct.new(redirect_uris: "https://a.example/cb", default_redirect_uri: "https://a.example/cb")
      allow(StandardId::ClientSecretCredential).to receive_message_chain(:active, :find_by).and_return(cred)

      flow = build_flow({ response_type: "code", client_id: "cid" })
      result = flow.execute
      expect(result[:redirect_to]).to eq("https://a.example/cb")
    end

    it "builds redirect URIs with query params" do
      # Expose helper via a subclass method
      helper_class = Class.new(described_class) do
        public :build_redirect_uri, :build_fragment_uri
      end
      helper = helper_class.new({}, request)

      url = helper.build_redirect_uri("https://a.example/cb?x=1", { code: "abc", state: "s" })
      expect(URI(url).query.split("&").sort).to match_array(["code=abc", "state=s", "x=1"])

      frag = helper.build_fragment_uri("https://a.example/cb", { access_token: "tok 1", token_type: "Bearer" })
      expect(URI(frag).fragment).to include("access_token=tok+1")
      expect(URI(frag).fragment).to include("token_type=Bearer")
    end

    it "execute runs validations, authenticates client, then returns subclass response" do
      cred = OpenStruct.new(redirect_uris: "https://a.example/cb", default_redirect_uri: "https://a.example/cb")
      allow(StandardId::ClientSecretCredential).to receive_message_chain(:active, :find_by).and_return(cred)

      flow = build_flow({ response_type: "token", client_id: "cid", scope: "read", state: "xyz" })
      result = flow.execute
      expect(result).to include(ok: true, redirect_to: "https://a.example/cb", scope: "read", state: "xyz")
    end
  end
end
