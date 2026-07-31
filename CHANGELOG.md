# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
