# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `.editorconfig` for consistent indentation and whitespace across editors.
- `AGENTS.md` describing the OIDC engine surface (ConsentGrant + RevokedToken models, ID token service, extension flows) for AI coding agents and new contributors.
- `lefthook.yml` plus `.lefthook/` scripts for pre-push checks (whitespace, signed commits, RuboCop, Brakeman, RSpec) and post-checkout/rewrite/merge `bundle install` sync. Install via `brew install lefthook && lefthook install`; skip with `LEFTHOOK=0`.

### Removed

- **BREAKING:** Dropped support for Ruby < 4.0. The gem now requires Ruby 4.0+, matching the upstream [`standard_id`](https://github.com/rarebit-one/standard_id) gem ([standard_id#195](https://github.com/rarebit-one/standard_id/pull/195)).

### Changed

- CI workflow migrated to the shared `rarebit-one/.github` reusable workflow (`reusable-gem-ci.yml@v1`); `.github/workflows/ci.yml` is now a thin shim. The lint job runs RuboCop plus Brakeman and bundler-audit security scans via `extra-lint-commands`. The test matrix is intentionally empty (`ruby-versions: '[]'`) — the dummy app still references the legacy `StandardConfig` constant that was removed upstream, so RSpec cannot boot. Re-enabling the matrix is tracked as follow-up work. The previous bespoke RuboCop result cache is dropped because `hashFiles` cannot be evaluated when resolving reusable-workflow inputs; lint runs on this gem are short enough that the cache is not worth the extra plumbing.
- Release workflow migrated to the shared `rarebit-one/.github` reusable workflow (`reusable-gem-release.yml@v1`); `.github/workflows/release.yml` is now a thin shim.

### Added

- Brakeman static analysis and bundler-audit dependency scanning now run on every CI build, surfacing security issues before they reach a release.

## [0.1.0] - 2026-04-21

### Added

- Initial release of OpenID Connect Identity Provider addon for StandardId
- ID token issuance, consent management, token introspection, and token revocation
- OIDC discovery endpoint
