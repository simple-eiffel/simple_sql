# SIMPLE_SQL World-Class SQLite Library Roadmap

---

## Claude: Start Here

**When starting a new conversation, read this file first.**

### Session Startup

1. **Read Eiffel reference docs**: `D:/prod/reference_docs/eiffel/CLAUDE_CONTEXT.md`
2. **Review this roadmap** for project-specific context
3. **Ask**: "What would you like to work on this session?"

### Key Reference Files

| File | Purpose |
|------|---------|
| `D:/prod/reference_docs/eiffel/CLAUDE_CONTEXT.md` | Generic Eiffel knowledge |
| `D:/prod/reference_docs/eiffel/gotchas.md` | Generic Eiffel gotchas |
| `D:/prod/reference_docs/eiffel/sqlite_gotchas.md` | SQLite-specific gotchas |
| `D:/prod/reference_docs/eiffel/HATS.md` | Focused work modes |
| `D:/prod/reference_docs/eiffel/patterns.md` | Verified code patterns |

### Build & Test Commands

```batch
:: Compile
ec.exe -batch -config "D:\prod\simple_sql\simple_sql.ecf" -target simple_sql_tests -c_compile -freeze

:: Run tests
ec.exe -batch -config "D:\prod\simple_sql\simple_sql.ecf" -target simple_sql_tests -tests
```

### Current Status

**Stable / Maintenance Mode** - 361 tests passing

Primary work now:
- Contract strengthening (Contracting Hat)
- Test coverage improvements (Testing Hat)
- Bug fixes via mock applications (Mock Building Hat)

---

## Mock-Driven Development Process

SIMPLE_SQL is developed using **Mock-Driven Development** - building realistic consumer applications to drive API improvements.

### Why Mock Apps?

1. **Expose real friction** - Unit tests verify correctness; mock apps reveal usability problems
2. **Drive boilerplate elimination** - Every convenience method exists because a real app needed it
3. **Integration testing** - Mock apps serve as comprehensive integration tests
4. **Documentation by example** - Working apps show how to use the library

### Current Mock Applications

| Target | Domain | Complexity | Key Friction Exposed | API Improvements Driven |
|--------|--------|------------|---------------------|------------------------|
| `todo_app` | Task management | Basic CRUD | Query builder basics | Initial patterns, fluent API |
| `cpm_app` | Project scheduling | 51 activities, 65 dependencies | Parameterized queries | `execute_with_args`, `query_with_args` |
| `habit_tracker` | Time-series data | Daily tracking, streaks | Aggregations, soft deletes | Streaming cursors, date utilities |
| `dms` | Document management | Hierarchical folders, versioning, FTS, audit | **N+1 queries, pagination, boilerplate** | **Eager loading, soft delete scopes, pagination builder, N+1 detection** |
| `wms` | Warehouse/Inventory | Stock management, reservations, movements | **Optimistic locking, atomic operations, upsert, concurrent access** | **Phase 6 candidates** |

### The Process

```
1. Choose a domain (different from previous mocks)
2. Build a realistic application using SIMPLE_SQL
3. Note friction points (boilerplate, awkward patterns)
4. Add convenience methods to eliminate friction
5. Add tests for new API features
6. Verify mock app code simplifies
7. Repeat with next domain
```

### Lessons Learned from Each Mock

**TODO App:** Basic patterns work well. Fluent query builder is intuitive.

**CPM App:** Parameterized queries eliminate SQL injection risk and make code cleaner. Heavy relationship traversal needs thought.

**Habit Tracker:** Time-series queries benefit from streaming cursors. Soft delete pattern is common but repetitive.

**DMS:** The N+1 problem is real and insidious. Cursor-based pagination is complex to implement correctly. Soft delete boilerplate clutters every query. Audit trails need trigger-based approach.

**WMS:** Optimistic locking requires manual version check + retry loop boilerplate. Atomic multi-table operations (stock + movement audit) need transaction scaffolding. Upsert pattern (receive to existing location) is awkward. Concurrent reservation access has race condition potential. These friction points drive Phase 6 improvements.

### Potential Future Mocks

- **Reporting Dashboard** - Complex aggregations, window functions, exports
- **Chat Application** - Real-time patterns, message threading, read receipts

---

## Current State

**Phases 1-6 Complete.** The library now includes:
- **SIMPLE_SQL_DATABASE**: Full CRUD, transactions, streaming, error handling, BLOB utilities, query monitoring
- **SIMPLE_SQL_RESULT/ROW**: Query results with typed accessors, BLOB support
- **SIMPLE_SQL_CURSOR**: Lazy row-by-row iteration
- **SIMPLE_SQL_RESULT_STREAM**: Callback-based streaming
- **SIMPLE_SQL_PREPARED_STATEMENT**: Parameterized queries with streaming, BLOB/hex encoding, named parameters
- **SIMPLE_SQL_SELECT_BUILDER**: Fluent SELECT with soft delete scopes (`.active_only`, `.deleted_only`, `.with_deleted`)
- **SIMPLE_SQL_INSERT/UPDATE/DELETE_BUILDER**: Fluent DML builders
- **SIMPLE_SQL_SCHEMA**: Schema introspection
- **SIMPLE_SQL_MIGRATION_RUNNER**: Version-controlled migrations
- **SIMPLE_SQL_PRAGMA_CONFIG**: Database configuration
- **SIMPLE_SQL_BATCH**: Bulk operations
- **SIMPLE_SQL_BACKUP**: Memory/file database copying, online backup, export/import
- **SIMPLE_SQL_ERROR**: Structured error handling
- **SIMPLE_SQL_FTS5**: Full-text search with BM25 ranking
- **SIMPLE_SQL_FTS5_QUERY**: Fluent FTS5 query builder
- **SIMPLE_SQL_JSON**: JSON1 extension with validation, path queries, modification, aggregation
- **SIMPLE_SQL_AUDIT**: Automatic audit/change tracking with trigger generation
- **SIMPLE_SQL_REPOSITORY**: Generic repository pattern with CRUD operations
- **SIMPLE_SQL_VECTOR**: Vector embeddings with math operations
- **SIMPLE_SQL_VECTOR_STORE**: Vector storage with KNN search
- **SIMPLE_SQL_SIMILARITY**: Distance and similarity metrics
- **SIMPLE_SQL_ONLINE_BACKUP**: SQLite Online Backup API with progress callbacks
- **SIMPLE_SQL_EXPORT**: Export to CSV, JSON, SQL dump formats
- **SIMPLE_SQL_IMPORT**: Import from CSV, JSON, SQL formats
- **SIMPLE_SQL_EAGER_LOADER**: N+1 query prevention with `.include()` API (NEW)
- **SIMPLE_SQL_EAGER_RESULT**: Eager loading result container (NEW)
- **SIMPLE_SQL_PAGINATOR**: Cursor-based pagination builder (NEW)
- **SIMPLE_SQL_PAGE**: Pagination result with cursor management (NEW)
- **SIMPLE_SQL_QUERY_MONITOR**: N+1 query detection and warnings (NEW)
- **Phase 6 Atomic Operations**: `atomic()`, `update_versioned()`, `upsert()`, `decrement_if()`, `increment_if()` (NEW)

**500+ tests (100% passing). Production-ready for all features. 5 mock applications demonstrate real-world usage.**

Test expansion complete based on Grok code review (see `D:/prod/reference_docs/eiffel/SIMPLE_SQL_TEST_EXPANSION_PLAN.md`):
- ✅ Priority 1: Backup/Import/Export Edge Cases (8 tests)
- ✅ Priority 2: Vector Embeddings Edge Cases (8 tests)
- ✅ Priority 3: Error Handling & Recovery (6 tests) - 2 removed (DBC enforces)
- ✅ Priority 4: Migration & Schema Edge Cases (7 tests)
- ✅ Priority 5: FTS5 Extended Coverage (5 tests) - 1 removed (DBC enforces)
- ✅ Priority 6: Query Builder Edge Cases (6 tests)
- ✅ Priority 7: JSON Advanced Edge Cases (6 tests)
- ✅ Priority 8: Streaming & Performance (4 tests)

**Total: 51 edge case tests added (50 implemented + 3 removed for DBC redundancy)**

---

## Proposed Architecture

### Phase 1 - Core Excellence ✅ COMPLETE

| Feature | Description | Status |
|---------|-------------|--------|
| **Prepared Statements** | Cached, parameterized queries with bind variables for security and performance | ✅ |
| **WAL Mode & PRAGMA Config** | Auto-configure optimal settings (WAL, synchronous=normal, mmap, busy_timeout) | ✅ |
| **Batch Operations** | Bulk insert/update/delete with automatic transaction wrapping | ✅ |
| **Enhanced Error Handling** | Error codes, structured error information | ✅ |

### Phase 2 - Developer Experience ✅ COMPLETE

| Feature | Description | Status |
|---------|-------------|--------|
| **Fluent Query Builder** | Chainable SELECT/INSERT/UPDATE/DELETE construction | ✅ |
| **Schema Introspection** | Query table structure, columns, indexes, foreign keys | ✅ |
| **Migration System** | Version tracking via user_version PRAGMA, migration runner | ✅ |

### Phase 3 - Performance Optimization ✅ COMPLETE

| Feature | Description | Status |
|---------|-------------|--------|
| **Query Result Streaming** | Lazy cursor iteration, callback-based processing | ✅ |
| **Lazy Loading** | Row-by-row fetching for large result sets | ✅ |
| **Cursor-Based Iteration** | Memory-efficient `across` loop support | ✅ |

### Phase 4 - Advanced Features ✅ COMPLETE

| Feature | Description | Status |
|---------|-------------|--------|
| **FTS5 Full-Text Search** | Virtual table setup, MATCH queries, BM25 ranking, Boolean queries, special character handling | ✅ |
| **BLOB Handling** | File I/O utilities, hex encoding, named parameter binding, large binary data support | ✅ |
| **JSON1 Extension** | JSON validation, path queries, modification (set/insert/replace/remove), creation, aggregation | ✅ |
| **Audit/Change Tracking** | Auto-generate triggers, change log table, JSON diff logging, change history queries | ✅ |
| **Repository Pattern** | Generic repository with find_all, find_by_id, find_where, pagination, CRUD operations | ✅ |

### Phase 5 - Specialized ✅ COMPLETE

| Feature | Description | Status |
|---------|-------------|--------|
| **Vector Embeddings** | Store REAL_64 arrays, cosine similarity, K-nearest neighbors | ✅ |
| **Advanced Backup** | Online backup API with progress callbacks, incremental backup, export/import (CSV, JSON, SQL) | ✅ |

### Phase 6 - Concurrency & Atomic Operations (WMS-Driven) ✅ COMPLETE

Friction points identified by the WMS (Warehouse Management System) mock application, now implemented:

| Feature | Friction ID | API | Status |
|---------|-------------|-----|--------|
| **Atomic Operations** | F2 | `db.atomic(agent)` - Transaction wrapper with auto-rollback | ✅ |
| **Optimistic Locking** | F1 | `db.update_versioned(table, id, version, set, args)` - Returns success/new_version | ✅ |
| **Upsert Pattern** | F4 | `db.upsert(table, columns, values, conflict_columns)` - INSERT ON CONFLICT | ✅ |
| **Conditional Decrement** | F3 | `db.decrement_if(table, col, amount, where, args)` - Atomic check + update | ✅ |
| **Conditional Increment** | F3 | `db.increment_if(table, col, amount, where, args)` - Atomic check + update | ✅ |

**16 tests added in TEST_PHASE6_ATOMIC. WMS refactored to use new APIs.**

---

## Class Structure

```
SIMPLE_SQL_DATABASE (core)
+-- SIMPLE_SQL_PREPARED_STATEMENT
+-- SIMPLE_SQL_PRAGMA_CONFIG
+-- SIMPLE_SQL_QUERY_MONITOR ✅ NEW (N+1 detection)

SIMPLE_SQL_QUERY_BUILDER
+-- SIMPLE_SQL_SELECT_BUILDER (with soft delete scopes)
+-- SIMPLE_SQL_INSERT_BUILDER
+-- SIMPLE_SQL_UPDATE_BUILDER
+-- SIMPLE_SQL_DELETE_BUILDER

SIMPLE_SQL_SCHEMA
+-- SIMPLE_SQL_MIGRATION
+-- SIMPLE_SQL_MIGRATION_RUNNER
+-- SIMPLE_SQL_TABLE_INFO
+-- SIMPLE_SQL_COLUMN_INFO

SIMPLE_SQL_FTS5
+-- SIMPLE_SQL_FTS5_QUERY

SIMPLE_SQL_AUDIT
    (Auto-generate INSERT/UPDATE/DELETE triggers)
    (Query change history, detect changed fields)

SIMPLE_SQL_REPOSITORY [G]
    (Generic deferred class for CRUD operations)
    (find_all, find_by_id, find_where, pagination, ordering)
    (insert, update, save, delete, count, exists)

SIMPLE_SQL_VECTOR
+-- SIMPLE_SQL_VECTOR_STORE
+-- SIMPLE_SQL_SIMILARITY
+-- AGENT_PART_COMPARATOR (helper for library sorting)

SIMPLE_SQL_RESULT (eager loading)
+-- SIMPLE_SQL_ROW

SIMPLE_SQL_CURSOR (lazy iteration)
+-- SIMPLE_SQL_CURSOR_ITERATOR

SIMPLE_SQL_RESULT_STREAM (callback streaming)

SIMPLE_SQL_BACKUP
+-- SIMPLE_SQL_ONLINE_BACKUP
+-- SIMPLE_SQL_EXPORT
+-- SIMPLE_SQL_IMPORT

SIMPLE_SQL_EAGER_LOADER ✅ NEW (N+1 query prevention)
+-- SIMPLE_SQL_EAGER_RESULT ✅ NEW

SIMPLE_SQL_PAGINATOR ✅ NEW (cursor-based pagination)
+-- SIMPLE_SQL_PAGE ✅ NEW
```

---

## Research Sources

- [Rusqlite - Ergonomic SQLite for Rust](https://github.com/rusqlite/rusqlite)
- [Kysely - Type-safe SQL Query Builder](https://kysely.dev/)
- [SQLite Performance Tuning](https://phiresky.github.io/blog/2020/sqlite-performance-tuning/)
- [SQLite FTS5 Extension](https://www.sqlite.org/fts5.html)
- [sqlite-migrate](https://github.com/simonw/sqlite-migrate)
- [SQLite Hybrid Search](https://alexgarcia.xyz/blog/2024/sqlite-vec-hybrid-search/index.html)
- [JSON Audit Log](https://til.simonwillison.net/sqlite/json-audit-log)
- [SQLAlchemy Connection Pooling](https://docs.sqlalchemy.org/en/20/core/pooling.html)
- [Declarative Schema Migration](https://david.rothlis.net/declarative-schema-migration-for-sqlite/)

---

## Documentation

**HTML Documentation with EIS Integration** ✅ COMPLETE

Comprehensive HTML-based documentation with EiffelStudio integration via EIS (Eiffel Information System):

```
docs/
├── index.html              -- Main entry point with feature overview
├── getting-started.html    -- Quick start tutorial
├── css/style.css           -- Professional styling
├── api/                    -- API reference for all major classes
├── tutorials/              -- How-to guides (soft deletes, eager loading, pagination)
└── mock-apps/              -- Documentation for all 5 mock applications
```

**Key Features:**
- Press **F1** in EiffelStudio to open documentation for any annotated class
- HTML links navigate back to EiffelStudio: `eiffel:?class=SIMPLE_SQL_DATABASE&feature=query`
- Syntax-highlighted Eiffel code examples
- Feature cards, callout boxes, and responsive design
- Mock app documentation explaining which friction points drove which API improvements

**EIS Syntax in Eiffel Classes:**
```eiffel
note
    EIS: "name=API Reference", "src=../docs/api/database.html", "protocol=URI", "tag=documentation"
```

**EIS Links in HTML (back to EiffelStudio):**
```html
<a class="eis-link" href="eiffel:?class=SIMPLE_SQL_DATABASE&feature=query">View Source</a>
```

---

## Notes

- All development follows Eiffel Design by Contract principles
- Classes use ECMA-367 standard Eiffel
- Testing via EiffelStudio AutoTest framework
- Documentation via HTML with EIS integration for F1 help
