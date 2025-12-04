# Changelog

All notable changes to DesignAlgorithmsKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- N/A

### Changed
- N/A

### Deprecated
- N/A

### Removed
- N/A

### Fixed
- N/A

### Security
- N/A

## [1.1.0] - 2025-12-04

### Added
- **Queue Processing Pattern** - Concurrent queue management with status tracking, progress monitoring, and retry support
  - `QueueItem` protocol for items that can be processed in a queue
  - `QueueProcessor` protocol for processing queue items
  - `ProcessingQueue` actor for managing concurrent processing with configurable limits
  - Features: status tracking (pending, processing, completed, failed), progress monitoring (0.0 to 1.0), retry support, pause/resume functionality, cancellation, deduplication
  - Comprehensive unit tests (15 tests)
- **Merging/Upsert Pattern** - Configurable merge strategies for conflict resolution
  - `Mergeable` protocol for types that can be merged
  - `MergeStrategy` enum with strategies: preferExisting, preferNew, combine, custom
  - `Merger` protocol for merging items with configurable strategies
  - `DefaultMerger` base class with default implementations
  - Comprehensive unit tests (32 tests)
- Added comprehensive unit tests for new patterns
  - Queue Processing Pattern: 15 tests covering all features and edge cases
  - Merging/Upsert Pattern: 32 tests covering all strategies, edge cases, and protocol conformance
  - Total: 153 tests (was 123) ➕ +30 new tests

### Changed
- Updated README.md with usage examples for Queue Processing Pattern and Merging/Upsert Pattern
- Improved code coverage:
  - Overall: 96.15% lines (up from 96.06%)
  - Queue.swift: 89.23% regions, 91.50% lines
  - Merger.swift: 83.33% regions, 84.62% lines
- Enhanced documentation with comprehensive examples for new patterns

### Fixed
- N/A

## [1.0.3] - 2025-12-04

### Added
- Added comprehensive unit tests for Builder pattern (12 tests total)
  - Test for BaseBuilder default implementation (notImplemented error)
  - Tests for BuilderError localizedDescription for all error cases
  - Test for fluent API chaining with multiple method calls
  - Test for optional properties handling
  - Test for multiple independent builder instances
  - Test for ValidatingBuilderProtocol default implementation
  - Comprehensive validation tests with multiple rules
  - Test for error pattern matching
  - Test for builder reuse scenarios
- Added comprehensive unit tests to improve code coverage
  - Added tests for Singleton createShared() path and init()
  - Added tests for BaseStrategy and StrategyContext edge cases
  - Added tests for Factory error handling, thread safety, and edge cases
  - Added tests for Registry protocol method, default keys, and thread safety
- Added tests for HashAlgorithm extension fallback behavior
- Added test for HashAlgorithm string extension consistency
- Added SingletonError enum for better error handling in Singleton pattern

### Changed
- Refactored Singleton.createShared() to throw SingletonError instead of fatalError
  - Makes the error path testable while maintaining fatalError for production use
  - Improved Singleton function coverage from 50% to 80%
- Refactored HashAlgorithm extension to improve testability
  - Added documentation explaining UTF-8 conversion fallback behavior
  - Documented fallback hash path as conditionally untestable
- Improved overall code coverage:
  - Regions: 87.31% → 87.75%
  - Functions: 88.24% → 90.29%
  - Lines: 90.91% → 91.38%

### Fixed
- Fixed compiler warning in SingletonTests about 'is' test always being true
- Fixed Builder pattern testability - improved coverage to 100% (from 66.67%)
- Fixed test for StrategyContext with same strategy type

### Documentation
- Added documentation explaining why fatalError path in Singleton.shared cannot be tested
- Added documentation to HashAlgorithm fallback implementation explaining conditional testability
- Improved code documentation for testability throughout codebase

## [1.0.2] - 2025-12-04

### Fixed
- Fixed duplicate `import Foundation` statement in `MerkleTree.swift`
- Fixed compiler warnings in `BuilderTests.swift` about unused mutable variables
  - Changed `var newBuilder = self` pattern to direct `self` mutation
  - Since `BaseBuilder` is a class (reference type), we can mutate `self` directly

## [1.0.1] - 2025-12-04

### Changed
- Fixed workflow YAML syntax errors that prevented execution
- Renamed workflow file to `publish-github-pages.yml` for consistency with project standards
- Refactored workflow to use shell script approach matching the 'me' project pattern
- Added `publish-docc-to-github-pages.sh` script for documentation generation and publishing
- Updated permissions to use `contents:write` instead of `pages:write`
- Added Git configuration step for GitHub Actions
- Added support for `GH_PAT` token fallback for cross-repository access

## [1.0.0] - 2025-12-04

### Added
- Initial release with core design patterns and algorithms
- Registry Pattern implementation
- Factory Pattern implementation
- Builder Pattern implementation
- Singleton Pattern implementation
- Strategy Pattern implementation
- Observer Pattern implementation
- Facade Pattern implementation
- Adapter Pattern implementation
- Merkle Tree data structure
- Bloom Filter data structure
- Counting Bloom Filter variant
- SHA-256 hash algorithm
- Comprehensive unit test suite (67 tests)
- DocC documentation
- GitHub Actions CI/CD workflows
- Code coverage reporting

