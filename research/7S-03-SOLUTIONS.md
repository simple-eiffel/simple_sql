# 7S-03-SOLUTIONS: simple_sql


**Date**: 2026-01-23

**BACKWASH** | Date: 2026-01-23

## Alternative Solutions Considered

### 1. EiffelStore (EiffelStudio)
- **Pros**: Official Eiffel library, supports multiple databases
- **Cons**: Complex API, heavyweight, requires separate database setup
- **Decision**: Too complex for embedded use cases

### 2. Direct SQLite C Bindings
- **Pros**: Maximum control, minimal overhead
- **Cons**: No type safety, manual memory management, verbose
- **Decision**: Useful as foundation but needs wrapper

### 3. Third-party ODBC Wrappers
- **Pros**: Database-agnostic
- **Cons**: ODBC driver overhead, configuration complexity
- **Decision**: Not suitable for embedded scenarios

## Chosen Approach

**Inline C wrapper over SQLite with Eiffel-idiomatic API**

- SQLite bundled with EiffelStudio eliminates dependencies
- Inline C provides direct native access without separate DLLs
- Eiffel contracts ensure type safety and correctness
- Query builders provide fluent, readable SQL construction
- Repository pattern matches common OO design expectations

## Trade-offs Accepted

- SQLite-only (no database portability)
- File-based storage (not networked)
- Single-writer limitation (SQLite constraint)
