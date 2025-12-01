# SIMPLE_SQL World-Class SQLite Library Roadmap

---

## Claude: Start Here

**When starting a new conversation, read this file first.**

After reading this file, Claude should:

1. **Load additional context**:
   - `D:/prod/reference_docs/eiffel/CLAUDE_CONTEXT.md` - Eiffel language corrections
   - `D:/prod/reference_docs/eiffel/CURRENT_WORK.md` - Session state
   - `D:/prod/reference_docs/eiffel/gotchas.md` - Known issues

2. **Acknowledge**:
   - Confirm understanding of project state
   - Note which phase/feature we're working on
   - Flag any relevant gotchas

3. **Ask**: "What would you like to work on this session?"

### End of Session

Before ending, update:
- [ ] `D:/prod/reference_docs/eiffel/CURRENT_WORK.md` - Where we left off
- [ ] `D:/prod/reference_docs/eiffel/gotchas.md` - Any new discoveries
- [ ] This roadmap if phases/features changed

---

## Current State

**Phases 1-5 Complete.** The library now includes:
- **SIMPLE_SQL_DATABASE**: Full CRUD, transactions, streaming, error handling, BLOB utilities
- **SIMPLE_SQL_RESULT/ROW**: Query results with typed accessors, BLOB support
- **SIMPLE_SQL_CURSOR**: Lazy row-by-row iteration
- **SIMPLE_SQL_RESULT_STREAM**: Callback-based streaming
- **SIMPLE_SQL_PREPARED_STATEMENT**: Parameterized queries with streaming, BLOB/hex encoding, named parameters
- **SIMPLE_SQL_QUERY_BUILDER**: Fluent SELECT/INSERT/UPDATE/DELETE
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
- **SIMPLE_SQL_ONLINE_BACKUP**: SQLite Online Backup API with progress callbacks (NEW)
- **SIMPLE_SQL_EXPORT**: Export to CSV, JSON, SQL dump formats (NEW)
- **SIMPLE_SQL_IMPORT**: Import from CSV, JSON, SQL formats (NEW)

**339 tests (100% passing). Production-ready for all Phase 1-5 features.**

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

---

## Proposed Class Structure

```
SIMPLE_SQL_DATABASE (enhanced)
+-- SIMPLE_SQL_PREPARED_STATEMENT
+-- SIMPLE_SQL_PRAGMA_CONFIG

SIMPLE_SQL_QUERY_BUILDER
+-- SIMPLE_SQL_SELECT_BUILDER
+-- SIMPLE_SQL_INSERT_BUILDER
+-- SIMPLE_SQL_UPDATE_BUILDER
+-- SIMPLE_SQL_DELETE_BUILDER

SIMPLE_SQL_SCHEMA
+-- SIMPLE_SQL_MIGRATION
+-- SIMPLE_SQL_MIGRATION_RUNNER
+-- SIMPLE_SQL_TABLE_INFO
+-- SIMPLE_SQL_COLUMN_INFO

SIMPLE_SQL_FTS5 ✅ IMPLEMENTED
+-- SIMPLE_SQL_FTS5_QUERY ✅ IMPLEMENTED

SIMPLE_SQL_AUDIT ✅ IMPLEMENTED
    (Auto-generate INSERT/UPDATE/DELETE triggers)
    (Query change history, detect changed fields)

SIMPLE_SQL_REPOSITORY [G] ✅ IMPLEMENTED
    (Generic deferred class for CRUD operations)
    (find_all, find_by_id, find_where, pagination, ordering)
    (insert, update, save, delete, count, exists)

SIMPLE_SQL_VECTOR
+-- SIMPLE_SQL_VECTOR_STORE
+-- SIMPLE_SQL_SIMILARITY
+-- AGENT_PART_COMPARATOR (helper for library sorting)

SIMPLE_SQL_RESULT (eager loading)
+-- SIMPLE_SQL_ROW

SIMPLE_SQL_CURSOR (lazy iteration) ✅ NEW
+-- SIMPLE_SQL_CURSOR_ITERATOR

SIMPLE_SQL_RESULT_STREAM (callback streaming) ✅ NEW

SIMPLE_SQL_BACKUP (enhanced) ✅ IMPLEMENTED
+-- SIMPLE_SQL_ONLINE_BACKUP ✅ IMPLEMENTED
+-- SIMPLE_SQL_EXPORT ✅ IMPLEMENTED
+-- SIMPLE_SQL_IMPORT ✅ IMPLEMENTED
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

## Notes

- All development follows Eiffel Design by Contract principles
- Classes use ECMA-367 standard Eiffel
- Testing via EiffelStudio AutoTest framework
