module StandardId
  module Web
    module VerifyEmail
      class ConfirmController < BaseController
        before_action :prepare_code_challenge

        def show
          return redirect_to(standard_id_web.login_path, alert: "Invalid or expired verification code") if @challenge.nil?
          render plain: "verify email confirm", status: :ok
        end

        def update
          return redirect_to(standard_id_web.login_path, alert: "Invalid or expired verification code") if @challenge.nil?

          identifier = StandardId::EmailIdentifier.find_by(value: @challenge.target)
          if identifier.present?
            identifier.verify!
          end
          @challenge.use!

          redirect_to standard_id_web.login_path, notice: "Your email has been verified. Please sign in.", status: :see_other
        end

        private

        def prepare_code_challenge
          email = params[:email].to_s.strip.downcase
          code = params[:code].to_s
          return @challenge = nil if email.blank? || code.blank?

          @challenge = StandardId::CodeChallenge.active.find_by(
            realm: "verification",
            channel: "email",
            target: email,
            code: code
          )
        end
      end
    end
  end
end
