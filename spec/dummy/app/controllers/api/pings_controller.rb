module Api
  class PingsController < BaseController
    def show
      render json: { status: "ok", timestamp: Time.current.iso8601 }
    end
  end
end
