# AGENTS.md - AI Agent Guide for standard_id-provider

`standard_id-provider` is an OpenID Connect (OIDC) Identity Provider addon for the [`standard_id`](https://github.com/rarebit-one/standard_id) authentication engine. It extends StandardId with full OIDC capabilities: ID tokens, consent management, token introspection, token revocation, and a discovery endpoint.

## Quick Reference

```bash
# Run tests (against spec/dummy)
bundle exec rspec

# Run a single spec
bundle exec rspec spec/services/id_token_service_spec.rb

# Run linting
bundle exec rubocop
# or, with the explicit config (matches CI):
bundle exec rubocop --config .rubocop.yml

# Auto-fix lint issues
bundle exec rubocop -A

# Security scans (also run in CI)
bundle exec brakeman --no-pager --quiet
bundle exec bundle-audit check --update

# Database setup (uses spec/dummy app)
bundle exec rake app:db:setup
bundle exec rake app:db:migrate
```

## Project Structure

```
standard_id-provider/
├── app/
│   ├── controllers/standard_id/provider/   # OIDC endpoints
│   │   ├── discovery_controller.rb         # /.well-known/openid-configuration
│   │   ├── introspection_controller.rb     # RFC 7662 token introspection
│   │   └── revocation_controller.rb        # RFC 7009 token revocation
│   └── models/standard_id/provider/
│       ├── consent_grant.rb                # Per-client/per-user scope grants
│       └── revoked_token.rb                # Revocation registry
├── lib/standard_id/provider/
│   ├── engine.rb                           # Rails engine entrypoint
│   ├── config/schema.rb                    # Configuration DSL
│   ├── extensions/                         # Hooks into upstream standard_id flows
│   │   └── token_grant_flow_ext.rb         # Adds id_token issuance to grant flows
│   └── services/
│       └── id_token_service.rb             # ID token (JWT) issuance
├── config/routes.rb                        # OIDC routes
├── db/migrate/                             # consent_grants + revoked_tokens
└── spec/
    ├── dummy/                              # Test Rails app mounting both engines
    ├── controllers/                        # Discovery, introspection, revocation
    ├── extensions/                         # token_grant_flow_ext_spec.rb
    ├── models/                             # ConsentGrant, RevokedToken
    └── services/                           # id_token_service_spec.rb
```

## Key Concepts

### Engine Surface

This gem is a Rails engine mounted alongside `StandardId::WebEngine` and `StandardId::ApiEngine`. Routes are defined in `config/routes.rb` and mounted by the host app under whatever prefix it chooses (typically `/oidc`).

### Configuration

Defined in `lib/standard_id/provider/config/schema.rb` via the upstream `StandardConfig` DSL. Common values:

```ruby
StandardId.config.provider.id_token_lifetime           # 3600
StandardId.config.provider.scopes_supported            # %w[openid profile email offline_access]
StandardId.config.provider.claims_supported            # %w[sub iss aud exp iat nonce auth_time at_hash email name email_verified]
```

### Models

| Model | Table | Purpose |
|-------|-------|---------|
| `StandardId::Provider::ConsentGrant` | `standard_id_provider_consent_grants` | Records the scopes a user granted a client; checked on subsequent authorization requests |
| `StandardId::Provider::RevokedToken` | `standard_id_provider_revoked_tokens` | Append-only registry of revoked refresh/access tokens |

### Extension Pattern

`token_grant_flow_ext.rb` augments `StandardId`'s OAuth grant flows with ID token issuance. Extensions are loaded on engine boot and prepend behaviour onto upstream classes — be careful when modifying upstream method signatures.

### ID Token Service

`StandardId::Provider::IdTokenService` builds RFC 7519 JWTs signed with the host app's StandardId signing key. Standard claims: `iss`, `sub`, `aud`, `exp`, `iat`, `nonce`, `auth_time`, `at_hash`. Optional claims (email, profile) are gated by the granted scopes.

## Security Notes

- ID tokens are signed JWTs — never log them, never accept tokens whose `aud` does not match a registered client
- Token introspection (RFC 7662) requires authenticated client credentials; the gem rejects unauthenticated probes
- Token revocation (RFC 7009) is idempotent and writes to `standard_id_provider_revoked_tokens` — never mutate that table directly
- Consent grants are persisted per `(account, client)` pair; revoking a client's access should also delete the corresponding grant

## Testing

- Specs run against `spec/dummy`, a host Rails app that mounts both `standard_id` and `standard_id-provider` engines
- The dummy app needs migrations from upstream `standard_id` copied in (`bundle exec rake standard_id:install:migrations`)
- See `spec/support/` for shared request helpers and JWT decoding helpers
- `spec/extensions/token_grant_flow_ext_spec.rb` covers the integration boundary between this gem and upstream OAuth flows — keep it green when touching `lib/standard_id/provider/extensions/`

## Dependencies

- **rails** >= 8.0
- **standard_id** ~> 0.3 (peer engine providing accounts, sessions, OAuth flows)
- **brakeman**, **bundler-audit** (CI security scans)
- **rspec-rails** ~> 8.0, **shoulda-matchers** ~> 7.0 (test stack)
