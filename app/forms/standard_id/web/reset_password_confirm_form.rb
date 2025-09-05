module StandardId
  module Web
    class ResetPasswordConfirmForm
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :password, :string
      attribute :password_confirmation, :string

      attr_reader :password_credential

      validates :password,
        presence: { message: "cannot be blank" },
        length: { minimum: 8, too_short: "must be at least 8 characters long" },
        confirmation: { message: "confirmation doesn't match" }

      def initialize(password_credential, params = {})
        @password_credential = password_credential
        super(params)
      end

      def submit
        return false unless valid?

        ActiveRecord::Base.transaction do
          @password_credential.update!(password: password, password_confirmation: password_confirmation)
          @password_credential.account.sessions.destroy_all
        end

        true
      rescue ActiveRecord::RecordInvalid => e
        errors.add(:base, e.record.errors.full_messages.join(", "))
        false
      end
    end
  end
end
