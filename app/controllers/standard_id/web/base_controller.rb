module StandardId
  module Web
    class BaseController < ApplicationController
      include StandardId::WebAuthentication

      include StandardId::WebEngine.routes.url_helpers
      helper StandardId::WebEngine.routes.url_helpers

      layout "standard_id/web/application"

      before_action :require_browser_session!
    end
  end
end
