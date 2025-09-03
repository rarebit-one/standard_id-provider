module StandardId
  module Oauth
    module Subflows
      class Base
        def initialize(**params)
          @params = params
        end

        def call
          raise NotImplementedError, "Subclasses must implement #call"
        end

        private

        attr_reader :params
      end
    end
  end
end
