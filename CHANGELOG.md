# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-07-31

### Added

- **Install generator: `rails generate standard_id:provider:install`.** Copies
  the engine's migrations, writes a fully commented
  `config/initializers/standard_id_provider.rb`, and mounts the engine in
  `config/routes.rb`. Idempotent — re-running skips what is already installed.
  Flags: `--skip-migrations`, `--skip-initializer`, `--skip-routes`,
  `--mount-path PATH`, `--force`. Brings this gem in line with the five other
  family gems that ship one.

### Changed

- **A real README.** The previous one was the untouched `rails plugin new`
  scaffold ("Short description and motivation."). The new one documents what
  the gem is for, how to install and mount it, the two easily-missed settings
  (`discovery_endpoint_base`, `introspection_enabled`) — and, prominently, that
  **this engine `prepend`s into five non-public `standard_id` classes**,
  including a private controller method, so a consumer understands the coupling
  they are taking on and why the `~> 0.33` pin and `compat` job exist.
- `AGENTS.md` refreshed. It documented an introspection controller that no
  longer exists, the wrong table names (`standard_id_provider_consent_grants`
  → `standard_id_consent_grants`), a stale `StandardConfig` DSL name, the old
  `~> 0.3` pin, and lint commands CI no longer runs.
- `CLAUDE.md` corrected. It described this gem as "scaffolding for building
  StandardId provider plugins (like `standard_id-apple` and
  `standard_id-google`)". It is not — it is the OIDC Identity Provider addon,
  and has no relationship to those social-login plugins.

### Removed

- **BREAKING: `POST /api/provider/introspect` is gone.** `standard_id` 0.33.0
  ships an RFC 7662 endpoint of its own at `POST /oauth/introspect`, and core's
  is strictly more conformant: it renders `{"active": false}` and nothing else
  for *every* failure (RFC 7662 §2.2), where this gem's answered 401 with an
  error body on bad client credentials and 429 when throttled — the latter
  turning the rate limiter into a token-validity oracle. Core's is also
  404-gated behind `config.oauth.introspection_enabled`.

  The one thing worth keeping — core cannot see this engine's
  `RevokedToken` denylist, and says so ("this engine cannot invalidate a
  stateless JWT before its exp") — is now **contributed into** core's endpoint
  by `StandardId::Provider::Extensions::IntrospectionsControllerExt` rather than
  served by a second endpoint with different answers. Set
  `config.oauth.introspection_enabled = true`; the `RATE_LIMIT_INTROSPECT_PER_IP`
  env override is replaced by `config.rate_limits.introspection_per_ip`.
- **BREAKING: `config.provider.introspection_enabled` is removed.** It was
  declared, documented as a switch, and read by nothing — the endpoint it
  claimed to gate was always on. Use `config.oauth.introspection_enabled`.

### Fixed

- **The discovery document no longer hardcodes `/api`.** `DiscoveryController`
  interpolated every endpoint as `"#{issuer}/api/authorize"` and friends — the
  same defect core fixed in 0.33.0, wrong both because it assumed ApiEngine
  sits at exactly `/api` and because it conflated the issuer (a stable security
  identifier, RFC 8414 §2) with the endpoint base. The document is now built by
  `StandardId::Oauth::DiscoveryDocument` from
  `StandardId::Oauth::DiscoveryResolver`, so `config.oauth.discovery_endpoint_base`
  and `config.oauth.discovery_metadata_overrides` both work and the document
  cannot drift from the two core serves.

  **Hosts serving this document must set `discovery_endpoint_base`.** Unlike
  core's well-known controllers, this one is served from the *Provider* engine's
  mount, so `request.script_name` is not ApiEngine's mount path and `:request`
  would resolve to the origin root.
- **`config.provider.revocation_enabled` is now actually enforced.** It had the
  same never-read defect; `RevocationController` renders 404 when it is off.
- The document no longer advertises `response_types_supported: token` (nothing
  implements the implicit flow here) or `code_challenge_methods_supported: plain`
  (core enforces PKCE with S256 and rejects `plain`). It also drops its
  duplicate `id_token_signing_alg_values_supported`, which core derives from
  `config.oauth.signing_algorithm`.

### Changed

- `revocation_endpoint` in the discovery document points at this engine's
  `/api/provider/revoke` — built from the engine's route helper, so it follows
  the mount — rather than core's `/oauth/revoke`, because this engine's is the
  one that writes the denylist introspection consults.
- The dummy app now configures a real `issuer`, a `discovery_endpoint_base` and
  `oauth.introspection_enabled`, so the discovery and introspection paths are
  exercised against realistic config instead of `nil`.

### Changed

- **Tightened the `standard_id` dependency from `~> 0.3` to `~> 0.33`.** Both
  resolve to `< 1.0`, but the old form claimed compatibility back to 0.3 for an
  engine that `prepend`s into four non-public `StandardId::Oauth` classes —
  a claim nothing verified, because CI ran no tests. 0.33 is the oldest version
  the suite has actually been run against. The two-component form is
  deliberate: patch *and* minor `standard_id` releases roll through without a
  gemspec edit, avoiding the narrow-cap landmine of rarebit-one/rarebit-ops#278.

### Added

- **`compat` CI job.** Drops the lockfile, resolves against the latest
  *published* `standard_id`, and fails with an actionable message if the
  gemspec constraint excludes it — then runs the full suite against that
  version. Matches the job `standard_id-apple` and `standard_id-google` carry.

### Fixed

- **The dummy app now boots and the test suite runs.** `spec/dummy/config/database.yml`
  now sets `migrations_paths` explicitly to the union of the dummy app's own
  migrations and this engine's. Previously Rails fell back to
  `ActiveRecord::Migrator.migrations_paths`, whose default is the *relative*
  string `"db/migrate"` — resolved against RSpec's working directory (the gem
  root) that pointed at the engine's migrations, while `bin/rails app:db:migrate`
  used the dummy app's absolute path. The two disagreed, so
  `maintain_test_schema!` reported this engine's own migrations as permanently
  pending and aborted the suite before a single example ran. The CI workflow
  blamed an upstream `StandardConfig` rename; that was not the cause.
- `spec/support/oauth_helpers.rb` passed `redirect_uris` as an Array.
  `StandardId::ClientApplication` stores it as a whitespace-separated String
  (`#redirect_uris_array` splits on `/\s+/`), so every client-creating example
  failed validation.

### Added

- `spec/dummy/db/schema.rb` and the vendored `standard_id` migrations under
  `spec/dummy/db/migrate/*.standard_id.rb`, so a fresh checkout can build the
  test database with `bin/rails app:db:test:prepare`. Refresh them with
  `bin/rails app:standard_id:install:migrations && bin/rails app:db:migrate`.

### Changed

- **CI runs the real test suite again.** `ruby-versions` is now the family
  matrix (`4.0.0`–`4.0.4`) instead of `'[]'` (lint-only), with a
  `pre-test-commands` step to prepare the dummy database. `extra-lint-commands`
  is aligned with the rest of the family (`brakeman --no-pager --force`,
  `bundler-audit --update`).
- RuboCop excludes the generated `spec/dummy/db/schema.rb` and the vendored
  `standard_id` migration copies — upstream artifacts this gem does not own.

## [0.3.0] - 2026-07-12

### Added

- **Per-IP rate limiting on the token introspection (RFC 7662) and revocation
  (RFC 7009) endpoints.** Both are credential-guessable; the throttle runs
  *before* client authentication (30/15min by IP, override with
  `RATE_LIMIT_INTROSPECT_PER_IP` / `RATE_LIMIT_REVOKE_PER_IP`). Reuses the
  `standard_id` engine's rate-limit store and JSON 429 handler.

## [0.2.0] - 2026-04-29

### Added

- `.editorconfig` for consistent indentation and whitespace across editors.
- `AGENTS.md` describing the OIDC engine surface (ConsentGrant + RevokedToken models, ID token service, extension flows) for AI coding agents and new contributors.
- `lefthook.yml` plus `.lefthook/` scripts for pre-push checks (whitespace, signed commits, RuboCop, Brakeman, RSpec) and post-checkout/rewrite/merge `bundle install` sync. Install via `brew install lefthook && lefthook install`; skip with `LEFTHOOK=0`.
- SimpleCov branch coverage reporting wired into `spec/spec_helper.rb`. Reports are emitted to `coverage/` (gitignored). No minimum threshold is enforced — this enables visibility today, with a threshold to follow once the spec suite is reconciled with upstream `standard_id`.
- Brakeman static analysis and bundler-audit dependency scanning now run on every CI build, surfacing security issues before they reach a release.

### Changed

- CI workflow migrated to the shared `rarebit-one/.github` reusable workflow (`reusable-gem-ci.yml@v1`); `.github/workflows/ci.yml` is now a thin shim. The lint job runs RuboCop plus Brakeman and bundler-audit security scans via `extra-lint-commands`. The test matrix is intentionally empty (`ruby-versions: '[]'`) — the dummy app still references the legacy `StandardConfig` constant that was removed upstream, so RSpec cannot boot. Re-enabling the matrix is tracked as follow-up work. The previous bespoke RuboCop result cache is dropped because `hashFiles` cannot be evaluated when resolving reusable-workflow inputs; lint runs on this gem are short enough that the cache is not worth the extra plumbing.
- Release workflow migrated to the shared `rarebit-one/.github` reusable workflow (`reusable-gem-release.yml@v1`); `.github/workflows/release.yml` is now a thin shim.

### Removed

- **BREAKING:** Dropped support for Ruby < 4.0. The gem now requires Ruby 4.0+, matching the upstream [`standard_id`](https://github.com/rarebit-one/standard_id) gem ([standard_id#195](https://github.com/rarebit-one/standard_id/pull/195)).

## [0.1.0] - 2026-04-21

### Added

- Initial release of OpenID Connect Identity Provider addon for StandardId
- ID token issuance, consent management, token introspection, and token revocation
- OIDC discovery endpoint
