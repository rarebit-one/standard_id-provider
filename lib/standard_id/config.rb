module StandardId
  # Manages configuration for the StandardId engine
  #
  # Usage:
  #   StandardId.configure do |config|
  #     config.account_class_name = "User"
  #     config.cache_store = ActiveSupport::Cache::MemoryStore.new
  #     config.logger = Rails.logger
  #   end
  class Config
    # The name of the Account model class as a String, e.g. "User" or "Account"
    attr_accessor :account_class_name

    # Optional cache store and logger, used by StandardId.cache_store and StandardId.logger
    attr_accessor :cache_store, :logger

    # OAuth issuer identifier for ID tokens
    attr_accessor :issuer

    # Optional login URL for redirecting unauthenticated browser requests
    # Example: "/login" or a full URL like "https://app.example.com/login"
    # If set, Authorization endpoints can redirect to this path with a redirect_uri param
    attr_accessor :login_url

    def initialize
      @account_class_name = nil
      @cache_store = nil
      @logger = nil
      @issuer = nil
      @login_url = nil
    end

    def account_class
      account_class_name.constantize
    rescue NameError
      raise NameError, "Could not find account class: #{account_class_name}. Please set a valid class name using `StandardId.configure { |c| c.account_class_name = 'YourAccountClass' }`"
    end
  end
end
