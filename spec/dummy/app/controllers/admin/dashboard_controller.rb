module Admin
  class DashboardController < BaseController
    def index
      @accounts_count = Account.count
      @sessions_count = StandardId::Session.count
      @active_sessions_count = StandardId::Session.active.count
      @identifiers_count = StandardId::Identifier.count
      @credentials_count = StandardId::Credential.count
    end
  end
end
