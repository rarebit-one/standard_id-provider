module StandardId
  module Oauth
    # Shared base for all OAuth flows to handle params DSL and request context
    # Used by both token grant flows and authorization endpoint flows
    class BaseRequestFlow
      attr_reader :params, :request

      def initialize(params, request)
        @params = params
        @request = request
      end

      class << self
        def expect_params(*keys)
          @expected_params ||= []
          @expected_params |= keys.flatten.map! { |k| k.to_sym }
        end

        def permit_params(*keys)
          @permitted_params ||= []
          @permitted_params |= keys.flatten.map! { |k| k.to_sym }
        end

        def expected_params
          Array(@expected_params).dup
        end

        # Subclasses can append additional keys by overriding extra_permitted_keys
        def permitted_params
          exp = expected_params
          perm = Array(@permitted_params)
          configured = (exp + perm + Array(extra_permitted_keys)).uniq
          configured
        end

        def extra_permitted_keys
          []
        end
      end
    end
  end
end
