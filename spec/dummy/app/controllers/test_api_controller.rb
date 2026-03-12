class TestApiController < StandardId::Api::BaseController
  rescue_from StandardId::InvalidRequestError, with: :handle_invalid_request

  def show
    render json: { message: "success" }
  end

  private

  def handle_invalid_request(exception)
    render json: {
      error: "invalid_request",
      error_description: exception.message
    }, status: :bad_request
  end
end
