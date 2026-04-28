# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `.editorconfig` for consistent indentation and whitespace across editors.
- `AGENTS.md` describing the OIDC engine surface (ConsentGrant + RevokedToken models, ID token service, extension flows) for AI coding agents and new contributors.
- `lefthook.yml` plus `.lefthook/` scripts for pre-push checks (whitespace, signed commits, RuboCop, Brakeman, RSpec) and post-checkout/rewrite/merge `bundle install` sync. Install via `brew install lefthook && lefthook install`; skip with `LEFTHOOK=0`.
- SimpleCov branch coverage reporting wired into `spec/spec_helper.rb`. Reports are emitted to `coverage/` (gitignored). No minimum threshold is enforced — this enables visibility today, with a threshold to follow once the spec suite is reconciled with upstream `standard_id`.

### Changed

- Release workflow migrated to the shared `rarebit-one/.github` reusable workflow (`reusable-gem-release.yml@v1`); `.github/workflows/release.yml` is now a thin shim. CI workflow remains bespoke (lint-only, with a RuboCop cache that the reusable contract doesn't expose).

## [0.1.0] - 2026-04-21

### Added

- Initial release of OpenID Connect Identity Provider addon for StandardId
- ID token issuance, consent management, token introspection, and token revocation
- OIDC discovery endpoint
