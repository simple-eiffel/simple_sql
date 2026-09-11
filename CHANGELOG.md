# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Class invariants are O(1) again: clauses that built an MML model (`x_model.count = count`) or walked a collection on every feature call were removed. An invariant runs on every call, so those made each call O(n) and any loop over the object O(n^2); simple_json read a 1434-element array in 158 s under DBC before the fix. Model and per-element facts stay in the postconditions of the features that establish them.
- Testing config updates, AutoTest fixes, .gitignore cleanup
- Add SCOOP concurrency capability
- Migrate to simple_testing library
- Replace hardcoded paths with environment variables
- new target for profiling
- Strengthened DBC Contracts
- more updates
- Assessment update
- AI Productivity Assessment-Comparison
- Phase 6 work on WMS

## [1.0.0] - 2025-12-08

### Added
- Initial release
- Core functionality implemented
- Test suite with comprehensive coverage
- Documentation and examples

[Unreleased]: https://github.com/simple-eiffel/simple_sql/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/simple-eiffel/simple_sql/releases/tag/v1.0.0
