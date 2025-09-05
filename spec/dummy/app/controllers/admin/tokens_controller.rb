module Admin
  class TokensController < BaseController
    def index
      # Note: This is a placeholder since we don't have a tokens table yet
      # In a real implementation, you'd query actual access tokens
      @tokens = []
      @message = "Token management not yet implemented - tokens are currently stateless JWTs"
    end

    def destroy
      # Note: Since we're using stateless JWTs, we can't actually revoke them
      # In a real implementation, you'd maintain a blacklist or use a tokens table
      redirect_to admin_tokens_path, alert: "Token revocation not supported for stateless JWTs"
    end
  end
end
