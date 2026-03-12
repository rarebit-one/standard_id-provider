module StandardId
  module Web
    module VerifyPhone
      class BaseController < StandardId::Web::BaseController
        skip_before_action :require_browser_session!
      end
    end
  end
end
