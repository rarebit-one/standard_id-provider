module StandardId
  module Api
    class BaseController < ActionController::API
      before_action :validate_content_type!

      after_action :set_no_store_headers

      protected

      def validate_content_type!
        return if request.media_type&.match?(%r{\Aapplication\/(.+\+)?json\z})
        raise StandardId::InvalidRequestError, "Content-Type must be application/json or application/*+json"
      end

      def set_no_store_headers
        response.headers["Cache-Control"] = "no-store"
        response.headers["Pragma"] = "no-cache"
      end
    end
  end
end
