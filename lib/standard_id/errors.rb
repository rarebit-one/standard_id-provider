module StandardId
  class NotAuthenticatedError < StandardError; end
  class InvalidsessionError < StandardError; end
  class ExpiredSessionError < InvalidsessionError; end
  class RevokedSessionError < InvalidsessionError; end
  class UnsupportedGrantTypeError < StandardError; end
  class MissingClientSecretCredentialsError < StandardError; end
  class InvalidClientSecretCredentialsError < StandardError; end
end
