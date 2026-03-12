module StandardId
  module Web
    module VerifyPhone
      class ConfirmController < BaseController
        before_action :prepare_code_challenge

        def show
          return redirect_to(standard_id_web.login_path, alert: "Invalid or expired verification code") if @challenge.nil?
          render plain: "verify phone confirm", status: :ok
        end

        def update
          return redirect_to(standard_id_web.login_path, alert: "Invalid or expired verification code") if @challenge.nil?

          identifier = StandardId::PhoneNumberIdentifier.find_by(value: @challenge.target)
          if identifier.present?
            identifier.verify!
          end
          @challenge.use!

          redirect_to standard_id_web.login_path, notice: "Your phone number has been verified. Please sign in.", status: :see_other
        end

        private

        def prepare_code_challenge
          phone = params[:phone_number].to_s.strip
          code = params[:code].to_s
          return @challenge = nil if phone.blank? || code.blank?

          @challenge = StandardId::CodeChallenge.active.find_by(
            realm: "verification",
            channel: "sms",
            target: phone,
            code: code
          )
        end
      end
    end
  end
end
