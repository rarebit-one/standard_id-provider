# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Release workflow migrated to the shared `rarebit-one/.github` reusable workflow (`reusable-gem-release.yml@v1`); `.github/workflows/release.yml` is now a thin shim. CI workflow remains bespoke (lint-only, with a RuboCop cache that the reusable contract doesn't expose).

## [0.1.0] - 2026-04-21

### Added

- Initial release of OpenID Connect Identity Provider addon for StandardId
- ID token issuance, consent management, token introspection, and token revocation
- OIDC discovery endpoint
