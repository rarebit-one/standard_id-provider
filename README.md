# StandardId::Provider

OpenID Connect Identity Provider addon for [`standard_id`](https://github.com/rarebit-one/standard_id).

`standard_id` gives you OAuth 2.0 — authorization codes, token exchange, refresh
tokens, sessions. This engine adds the parts that make it an **OpenID Connect
identity provider**:

| | |
|---|---|
| **ID tokens** | Signed OIDC ID tokens issued alongside access tokens, with `nonce`, `auth_time`, `at_hash` and `c_hash` |
| **Consent** | Per-`(account, client)` scope grants, checked on subsequent authorization requests |
| **Access-token revocation** | An RFC 7009 endpoint backed by a `jti` denylist — the thing that makes revoking a *stateless* access token actually bite |
| **Discovery** | `/.well-known/openid-configuration`, built from core's document builder so it cannot drift |

## Read this before adopting it

**This engine `prepend`s into non-public `standard_id` internals.** That is not
an implementation detail you can ignore — it is the coupling you are taking on.

It prepends into five classes, none of which are part of `standard_id`'s public
API and none of which carry a stability guarantee:

| Class | Why |
|---|---|
| `StandardId::Oauth::TokenGrantFlow` | issue an ID token with the access token; stamp `jti` |
| `StandardId::Oauth::AuthorizationCodeAuthorizationFlow` | carry `nonce` / consent through authorization |
| `StandardId::Oauth::Subflows::TraditionalCodeGrant` | ditto, for the traditional code grant |
| `StandardId::Oauth::AuthorizationCodeFlow` | ditto |
| `StandardId::Api::Oauth::IntrospectionsController` | contribute the revocation denylist into core's RFC 7662 endpoint (a **private** method) |

What that means in practice:

* **A `standard_id` minor release can break this gem** without breaking its own
  semver contract, because the coupling is to internals rather than API.
* The gemspec therefore pins `standard_id` to `~> 0.33` — the oldest version
  this gem's suite has actually been run against.
* A **`compat` CI job** resolves against the latest *published* `standard_id`
  and runs the full suite against it on every push, so a break surfaces here
  before it surfaces in your app.

If you want OIDC without that coupling, you want `standard_id` on its own plus
your own ID-token issuance. If you want the coupling handled for you, this is
the gem.

## Installation

```ruby
# Gemfile
gem "standard_id-provider"
```

```bash
bundle install
rails generate standard_id:provider:install
rails db:migrate
```

The generator:

* copies the engine's migrations (`consent_grants`, `revoked_tokens`) into
  `db/migrate/`
* writes `config/initializers/standard_id_provider.rb`
* mounts the engine in `config/routes.rb`

It is **idempotent** — re-running skips anything already installed and says so.

| Flag | Effect |
|---|---|
| `--skip-migrations` | leave `db/migrate/` alone |
| `--skip-initializer` | do not write the initializer |
| `--skip-routes` | do not touch `config/routes.rb` |
| `--mount-path PATH` | mount somewhere other than `/` |
| `--force` | overwrite an existing initializer |

## Mounting

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount StandardId::Provider::Engine => "/"
  mount StandardId::WebEngine => "/", as: :standard_id_web

  scope "api" do
    mount StandardId::ApiEngine => "/", as: :standard_id_api
  end
end
```

The engine serves, relative to its own mount:

| Route | What |
|---|---|
| `GET /.well-known/openid-configuration` | OIDC discovery document |
| `POST /api/provider/revoke` | RFC 7009 revocation — writes the `jti` denylist |
| `GET\|POST\|DELETE /api/provider/consent` | consent grant management |

Introspection is **not** here — see below.

## Configuration

The generator writes a fully commented initializer. Two settings are load-bearing
and easy to miss.

### `discovery_endpoint_base` — required

```ruby
StandardId.configure do |c|
  c.issuer = "https://auth.example.com"
  c.oauth.discovery_endpoint_base = ->(request:) { "#{request.base_url}/api" }
end
```

The **issuer** and the **endpoint base** are different things. The issuer is a
stable security identifier (RFC 8414 §2) that clients match byte-for-byte
against their discovery URL and against the `iss` claim of issued tokens. The
endpoint base is merely where the endpoints live.

This engine's discovery document is served from the *Provider* engine's mount.
Core's own well-known controllers sit inside the `ApiEngine` mount and can read
it out of `SCRIPT_NAME`; this one cannot. If you do not name the base, the
document will advertise URLs that 404.

Use `discovery_metadata_overrides` for members that cannot be derived — a
host-owned authorization shim, a deliberately narrower scope list. They are
applied last and win over everything else. Setting `issuer` there raises.

### `introspection_enabled` — opt-in, and it is core's endpoint

```ruby
c.oauth.introspection_enabled = true
```

RFC 7662 introspection is **core's** endpoint (`POST /oauth/introspect`), not
this engine's. It is off by default and 404s until you opt in.

This engine used to ship a second one. It no longer does, because core's is
strictly more conformant — RFC 7662 §2.2 requires every failure mode to render
`{"active": false}` and nothing else, and this gem's answered `401` on bad
client credentials and `429` when throttled, which let a caller distinguish
"your credentials are wrong" and "you are throttled" from "that token is not
valid". The 429 in particular was a token-validity oracle.

What this engine contributes instead is the one thing core cannot do alone.
Access tokens are stateless, so core "cannot invalidate a stateless JWT before
its `exp`". This engine's revocation endpoint maintains a `jti` denylist, and
`IntrospectionsControllerExt` teaches core's endpoint to consult it — so a
revoked access token introspects as inactive immediately rather than staying
active until it expires.

### Provider settings

```ruby
c.provider.id_token_lifetime      = 3600
c.provider.scopes_supported       = %w[openid profile email offline_access]
c.provider.claims_supported       = %w[sub iss aud exp iat nonce auth_time at_hash email name email_verified]
c.provider.subject_types_supported = %w[public]
c.provider.revocation_enabled     = true   # false renders /api/provider/revoke as 404
```

The `*_supported` lists are advertised in the discovery document. They describe
what you are willing to issue — narrow them rather than widen them.

## Development

```bash
bin/rails app:db:test:prepare        # build the dummy app's test database
bundle exec rspec
bundle exec rubocop --config .rubocop.yml
bundle exec brakeman --no-pager --force
bundle exec bundler-audit --update
```

Specs run against `spec/dummy`, a host app mounting this engine alongside
`StandardId::WebEngine` and `StandardId::ApiEngine`. `spec/dummy/db/schema.rb`
and the vendored `spec/dummy/db/migrate/*.standard_id.rb` are committed;
refresh them with:

```bash
bin/rails app:standard_id:install:migrations
bin/rails app:db:migrate
```

`spec/dummy/config/database.yml` sets `migrations_paths` explicitly. **Leave it
that way** — without it Rails falls back to the relative default `"db/migrate"`,
which resolves against RSpec's working directory rather than the dummy app, and
the suite aborts on permanently-pending migrations.

## Contributing

Bug reports and pull requests are welcome at
<https://github.com/rarebit-one/standard_id-provider>.

Work happens in a git worktree, never the main checkout — see `CLAUDE.md`.
Commits are signed. CI runs RuboCop, Brakeman, bundler-audit, the full suite on
Ruby 4.0.0–4.0.4, and the `compat` job against the latest published
`standard_id`.

## License

Available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
