module Admin
  class SessionsController < BaseController
    before_action :prepare_session, only: [:destroy]

    def index
      @sessions = StandardId::Session.includes(:account).order(created_at: :desc).limit(25)
    end

    def destroy
      @session.update!(revoked_at: Time.current)
      redirect_to admin_sessions_path, notice: "Session was successfully revoked."
    end

    private

    def prepare_session
      @session = StandardId::Session.find(params[:id])
    end
  end
end
