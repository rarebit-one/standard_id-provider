module StandardId
  module Web
    class ResetPasswordStartForm
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :email, :string

      attr_reader :password_credential, :token

      validates :email, presence: { message: "Please enter your email address" }, format: { with: URI::MailTo::EMAIL_REGEXP }

      def submit
        return false unless valid?

        if token.present?
          # TODO: send reset link via email
        end

        true
      end

      def password_credential
        @password_credential ||= identifier&.account&.credentials&.where(credentialable_type: "StandardId::PasswordCredential")&.sole&.credentialable
      end

      def token
        @token ||= password_credential&.generate_token_for(:password_reset)
      end

      private

      def identifier
        @identifier ||= StandardId::EmailIdentifier.find_by(value: email.to_s.strip.downcase)
      end
    end
  end
end
