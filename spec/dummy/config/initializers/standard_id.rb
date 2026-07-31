StandardId.configure do |c|
  c.account_class_name = "Account"

  # A real issuer, so the discovery specs assert against something. Without it
  # every endpoint resolved to a relative path and the document's own
  # "issuer must be configured" branch went untested.
  c.issuer = "https://issuer.example.com"

  # The dummy mounts ApiEngine under `/api` while the Provider engine sits at
  # `/`, which is exactly the split that makes `:request` the wrong answer:
  # the discovery controller's SCRIPT_NAME is the PROVIDER mount, not
  # ApiEngine's. Naming the base explicitly is the supported fix, and it is
  # what replaced the hardcoded "#{issuer}/api/..." interpolation.
  c.oauth.discovery_endpoint_base = ->(request:) { "#{request&.base_url}/api" }

  # Core's RFC 7662 endpoint is off by default (it 404s). This engine
  # contributes its revocation denylist into that endpoint rather than running
  # a second one, so a provider deployment turns it on.
  c.oauth.introspection_enabled = true
end
