# 7S-02-STANDARDS: simple_sql


**Date**: 2026-01-23

**BACKWASH** | Date: 2026-01-23

## Language Standards

- **Eiffel**: ECMA-367 compliant
- **SQL**: SQLite dialect (SQL92 subset with SQLite extensions)
- **C**: C99 for inline externals

## Platform Standards

- **Target OS**: Windows (primary), with portable SQLite core
- **Architecture**: x64 (tested), x86 (supported)
- **SQLite Version**: 3.x series (bundled with EiffelStudio)

## Simple Eiffel Ecosystem Standards

- Design by Contract (DBC) throughout
- Void safety enabled
- SCOOP compatibility where applicable
- Inline C pattern for native calls (no separate .c files)
- ECF-based project configuration

## Coding Standards

- Feature naming: snake_case
- Class naming: ALL_CAPS with underscores
- Contracts on all public features
- Invariants for class consistency
- Comments in note clauses

## Testing Standards

- TEST_SET_BASE inheritance for all test classes
- Comprehensive contract coverage
- Integration tests with actual database operations
