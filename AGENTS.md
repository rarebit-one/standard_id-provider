# AGENTS.md - AI Agent Guide for standard_id-provider

`standard_id-provider` is an OpenID Connect (OIDC) Identity Provider addon for the [`standard_id`](https://github.com/rarebit-one/standard_id) authentication engine. `standard_id` provides OAuth 2.0; this engine adds the OIDC layer on top: ID tokens, consent grants, an access-token revocation denylist, and the discovery document.

**It is not scaffolding for building provider plugins.** `standard_id-apple` and `standard_id-google` are social-login provider plugins and are unrelated to this gem despite the similar name.

## Quick Reference

```bash
# Build the dummy app's test database (required once per checkout)
bin/rails app:db:test:prepare

# Run tests (against spec/dummy)
bundle exec rspec
bundle exec rspec spec/services/id_token_service_spec.rb

# Lint — pass --config explicitly, this is what CI runs
bundle exec rubocop --config .rubocop.yml
bundle exec rubocop --config .rubocop.yml -A

# Security scans (also run in CI)
bundle exec brakeman --no-pager --force
bundle exec bundler-audit --update

# Refresh the vendored standard_id migrations + dummy schema
bin/rails app:standard_id:install:migrations
bin/rails app:db:migrate
```

## Project Structure

```
standard_id-provider/
├── app/
│   ├── controllers/standard_id/provider/
│   │   ├── discovery_controller.rb         # /.well-known/openid-configuration
│   │   ├── revocation_controller.rb        # RFC 7009 token revocation
│   │   └── consent_controller.rb           # consent grant management
│   └── models/standard_id/provider/
│       ├── consent_grant.rb                # Per-client/per-user scope grants
│       └── revoked_token.rb                # jti denylist
├── lib/
│   ├── generators/standard_id/provider/install/   # rails g standard_id:provider:install
│   └── standard_id/provider/
│       ├── engine.rb                       # Rails engine + all the prepends
│       ├── config/schema.rb                # Configuration DSL
│       ├── id_token_service.rb             # ID token (JWT) issuance
│       └── extensions/                     # Hooks into upstream standard_id
├── config/routes.rb
├── db/migrate/                             # consent_grants + revoked_tokens
└── spec/
    ├── dummy/                              # Test Rails app mounting all engines
    ├── controllers/ extensions/ generators/ models/ services/
    └── support/oauth_helpers.rb
```

## Key Concepts

### The prepends are the whole design — and the whole risk

`lib/standard_id/provider/engine.rb` prepends into **five non-public `standard_id` classes**. None are part of `standard_id`'s public API; a minor release can change them without breaking its own semver contract.

| Target | Extension | Why |
|---|---|---|
| `StandardId::Oauth::TokenGrantFlow` | `TokenGrantFlowExt` | issue an ID token with the access token; stamp `jti` |
| `StandardId::Oauth::AuthorizationCodeAuthorizationFlow` | `AuthorizationFlowExt` | carry `nonce` / consent through authorization |
| `StandardId::Oauth::Subflows::TraditionalCodeGrant` | `TraditionalCodeGrantExt` | ditto |
| `StandardId::Oauth::AuthorizationCodeFlow` | `AuthorizationCodeFlowExt` | ditto |
| `StandardId::Api::Oauth::IntrospectionsController` | `IntrospectionsControllerExt` | contribute the denylist into core's RFC 7662 endpoint (private method) |

The controller one is prepended in `config.to_prepare`, not the initializer: controllers are reloadable, so binding the boot-time class would drop the extension on every `reload!`.

Two guardrails exist because of this coupling — **do not weaken either**:

1. The gemspec pins `standard_id` to `~> 0.33` (two components: `>= 0.33, < 1.0`). A three-component cap is what created the landmine in `rarebit-one/rarebit-ops#278`.
2. The `compat` CI job resolves against the latest **published** `standard_id` and runs the suite against it.

### What lives here vs. in core

Core gained overlapping features in 0.33.0. The division is now:

| Concern | Owner |
|---|---|
| RFC 7662 introspection endpoint | **core** (`POST /oauth/introspect`, off unless `config.oauth.introspection_enabled`). This engine only contributes its denylist into it. |
| Access-token `jti` denylist | **this engine** — core cannot invalidate a stateless JWT before its `exp` |
| RFC 7009 revocation | both: core's `/oauth/revoke` kills sessions and refresh-token families; this engine's `/api/provider/revoke` writes the denylist. Collapsing them is open follow-up work. |
| Discovery document construction | **core** (`Oauth::DiscoveryResolver` + `Oauth::DiscoveryDocument`); this engine only overlays the OIDC IdP members |

If you are tempted to add a duplicate of something core has, check core first.

### Configuration

Defined in `lib/standard_id/provider/config/schema.rb` via the upstream `StandardId::ConfigSchema` DSL:

```ruby
StandardId.config.provider.id_token_lifetime            # 3600
StandardId.config.provider.scopes_supported             # %w[openid profile email offline_access]
StandardId.config.provider.claims_supported             # %w[sub iss aud exp iat nonce auth_time at_hash email name email_verified]
StandardId.config.provider.subject_types_supported      # %w[public]
StandardId.config.provider.revocation_enabled           # true; false -> /api/provider/revoke 404s
```

Two **core** settings a provider deployment must set: `config.oauth.discovery_endpoint_base` (required — this engine's discovery controller cannot detect the ApiEngine mount from its own `SCRIPT_NAME`) and `config.oauth.introspection_enabled`.

Config fields that nothing reads are a recurring defect here: `provider.introspection_enabled` and `provider.revocation_enabled` were both declared and never consulted. If you add a field, wire it and spec it in the same change.

### Models

| Model | Table | Purpose |
|-------|-------|---------|
| `StandardId::Provider::ConsentGrant` | `standard_id_consent_grants` | Scopes a user granted a client; checked on subsequent authorization requests |
| `StandardId::Provider::RevokedToken` | `standard_id_revoked_tokens` | `jti` denylist; `revoke!` is idempotent, `cleanup_expired!` prunes |

### ID Token Service

`StandardId::Provider::IdTokenService` builds RFC 7519 JWTs signed with the host app's StandardId signing key. Claims: `iss`, `sub`, `aud`, `exp`, `iat`, `nonce`, `auth_time`, `at_hash`, `c_hash`. Optional claims are gated by granted scopes.

## Security Notes

- ID tokens are signed JWTs — never log them, never accept tokens whose `aud` does not match a registered client
- **Never make introspection distinguish failure modes.** RFC 7662 §2.2 requires `{"active": false}` and nothing else for every failure — including bad credentials and a tripped rate limit. A 429 there is a token-validity oracle. This gem shipped one; it was removed, not "improved."
- Revocation writes `standard_id_revoked_tokens` — never mutate that table directly
- Consent grants are persisted per `(account, client)`; revoking a client's access should also delete the grant
- The discovery document must never advertise a capability nothing implements (`response_types_supported: token`, `code_challenge_methods_supported: plain`) — both were removed for that reason

## Testing

- Specs run against `spec/dummy`, mounting this engine plus `StandardId::WebEngine` and `StandardId::ApiEngine` (the latter under `/api`)
- **`spec/dummy/config/database.yml` sets `migrations_paths` explicitly — leave it.** Without it Rails falls back to the relative default `"db/migrate"`, which resolves against RSpec's CWD (the gem root) rather than the dummy app. That mismatch made `maintain_test_schema!` report the engine's own migrations as permanently pending and aborted the suite before a single example ran — which is why CI ran no tests at all until it was fixed.
- `spec/dummy/db/schema.rb` and `spec/dummy/db/migrate/*.standard_id.rb` are committed; RuboCop excludes them as upstream artifacts
- `spec/extensions/` covers the boundary with upstream OAuth flows — keep it green when touching `lib/standard_id/provider/extensions/`

## Dependencies

- **rails** >= 8.0
- **standard_id** ~> 0.33 (peer engine providing accounts, sessions, OAuth flows)
- **brakeman**, **bundler-audit** (CI security scans)
- **rspec-rails** ~> 8.0, **shoulda-matchers** ~> 7.0 (test stack)
