module StandardId
  class ServiceSession < Session
    belongs_to :owner, polymorphic: true, optional: true

    validates :service_name, presence: true
    validates :service_version, presence: true
    validates :owner, presence: true

    before_validation :set_default_expiry, on: :create

    def display_name
      "#{service_name} Service Session (v#{service_version})"
    end

    def service_info
      {
        name: service_name,
        version: service_version,
        type: "service"
      }
    end

    def self.default_expiry
      90.days.from_now # TODO: make this configurable
    end

    def refresh!
      # No-op for service sessions - they don't get refreshed
      # Services should create new sessions when needed
    end

    def stale?
      # Service sessions are never considered stale
      # They're valid until they expire or are revoked
      false
    end

    private

    def set_default_expiry
      self.expires_at ||= self.class.default_expiry
    end
  end
end
