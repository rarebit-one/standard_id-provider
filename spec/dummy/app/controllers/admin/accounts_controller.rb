module Admin
  class AccountsController < BaseController
    before_action :prepare_account, only: [:show]

    def index
      @accounts = Account.includes(:identifiers, :sessions).limit(25)
    end

    def show
      @identifiers = @account.identifiers.includes(:credentials)
      @sessions = @account.sessions.order(created_at: :desc).limit(10)
    end

    private

    def prepare_account
      @account = Account.find(params[:id])
    end
  end
end
