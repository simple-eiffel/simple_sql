# SIMPLE_SQL

**High-level SQLite API for Eiffel**

A production-quality, easy-to-use wrapper around the Eiffel SQLite3 library, providing a clean, intuitive interface for database operations with comprehensive error handling and Design by Contract principles.

## Features

### ✅ Implemented (v0.2)

**Core Database Operations:**
- Simple database creation (file-based and in-memory)
- Execute SQL commands with automatic error handling
- Query execution with structured result sets
- Read-only database access
- Transaction support (begin, commit, rollback)
- Row/column metadata access

**Data Access:**
- Type-safe value retrieval (STRING, INTEGER, REAL, BOOLEAN)
- NULL value handling
- Column access by name or index
- Result iteration with automatic resource cleanup

**Prepared Statements & SQL Injection Prevention:**
- Parameterized queries with `?` placeholders
- Type-safe parameter binding (bind_text, bind_integer, bind_real, bind_null)
- Automatic value escaping for dynamic SQL
- Statement reset and rebind capabilities
- Full protection against SQL injection attacks

**Enhanced Error Handling:**
- SIMPLE_SQL_ERROR with error codes, messages, and context
- SIMPLE_SQL_ERROR_CODE with standard SQLite error constants
- Detailed error categorization (is_constraint_violation, is_syntax_error, etc.)
- Query text preservation in error context
- Error chaining support (cause references)

**PRAGMA Configuration:**
- SIMPLE_SQL_PRAGMA_CONFIG for SQLite runtime configuration
- Journal mode control (WAL, DELETE, TRUNCATE, MEMORY, OFF)
- Synchronous mode settings (FULL, NORMAL, OFF)
- Foreign key enforcement toggle
- Cache size configuration
- Busy timeout settings
- Preset configurations (fast_writes, safe, development, production)

**Batch Operations:**
- SIMPLE_SQL_BATCH for efficient bulk operations
- Transaction-wrapped batch execution
- Multiple statement execution in single call
- Batch insert with automatic transaction management

**Fluent Query Builders:**
- SIMPLE_SQL_SELECT_BUILDER with method chaining
- SIMPLE_SQL_INSERT_BUILDER with set() and values() methods
- SIMPLE_SQL_UPDATE_BUILDER with increment/decrement helpers
- SIMPLE_SQL_DELETE_BUILDER with safety guards
- Full WHERE clause support (where, and_where, or_where, where_equals)
- JOIN support (inner, left, right, cross)
- ORDER BY, GROUP BY, HAVING, LIMIT, OFFSET clauses

**Schema Introspection:**
- SIMPLE_SQL_SCHEMA for database structure inspection
- Table and view enumeration
- Column information (name, type, nullability, default, primary key)
- Index inspection with column details
- Foreign key relationship queries
- Schema version tracking (user_version, schema_version)

**Migration Framework:**
- SIMPLE_SQL_MIGRATION base class for versioned changes
- SIMPLE_SQL_MIGRATION_RUNNER for migration management
- Version-tracked schema changes using PRAGMA user_version
- Up/down migration support
- migrate_to() for targeting specific versions
- Automatic rollback on failure
- reset() for fresh database state

**Advanced Features:**
- Memory ↔ File backup utilities
- JSON integration with SIMPLE_JSON library
- Change tracking (affected row counts)
- Comprehensive test suite (131 tests)

**Design Principles:**
- Command-Query Separation throughout
- Comprehensive Design by Contract
- Void-safety compliant
- Unicode (STRING_32) support
- Automatic resource management

## Quick Start

```eiffel
-- Create database
create db.make ("myapp.db")

-- Execute DDL
db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)")

-- Insert data using query builder (SQL injection safe)
l_id := db.insert_builder.into ("users").set ("name", "Alice").set ("age", 30).execute_returning_id

-- Query data using fluent builder
result := db.select_builder.select_all.from_table ("users")
    .where ("age > 25").order_by ("name").execute
across result.rows as ic loop
    print (ic.string_value ("name"))
    print (ic.integer_value ("age"))
end

-- Prepared statements for repeated queries
create stmt.make ("SELECT * FROM users WHERE age > ?", db)
stmt.bind_integer (1, 25)
result := stmt.execute_query

-- Update with builder
db.update_builder.table ("users").set ("age", 31).where_equals ("name", "Alice").execute

-- Transactions
db.begin_transaction
db.execute ("INSERT INTO users VALUES (2, 'Bob', 25)")
db.commit

-- Cleanup
db.close
```

## Prepared Statements (SQL Injection Prevention)

```eiffel
-- Create parameterized statement
create stmt.make ("INSERT INTO users (name, age) VALUES (?, ?)", db)
stmt.bind_text (1, "Charlie")
stmt.bind_integer (2, 28)
stmt.execute_modify

-- Reset and rebind for another insert
stmt.reset
stmt.bind_text (1, "Diana")
stmt.bind_integer (2, 35)
stmt.execute_modify
```

## Fluent Query Builders

```eiffel
-- SELECT with full clause support
result := db.select_builder
    .select_column ("name").select_column ("age")
    .from_table ("users")
    .join ("orders", "orders.user_id = users.id")
    .where ("age > 18")
    .and_where ("status = 'active'")
    .order_by_desc ("created_at")
    .limit (10).offset (20)
    .execute

-- INSERT returning generated ID
l_id := db.insert_builder
    .into ("users")
    .set ("name", "Eve")
    .set ("age", 29)
    .execute_returning_id

-- UPDATE with increment
db.update_builder
    .table ("products")
    .increment ("views")
    .where_equals ("id", 42)
    .execute

-- DELETE with safety (requires WHERE or explicit execute_all)
db.delete_builder
    .from_table ("sessions")
    .where ("expires_at < datetime('now')")
    .execute
```

## Schema Migrations

```eiffel
-- Define migrations as classes
class MIGRATION_001 inherit SIMPLE_SQL_MIGRATION feature
    version: INTEGER = 1
    description: STRING = "Create users table"

    up (a_db: SIMPLE_SQL_DATABASE)
        do a_db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)") end

    down (a_db: SIMPLE_SQL_DATABASE)
        do a_db.execute ("DROP TABLE users") end
end

-- Run migrations
create runner.make (db)
runner.add (create {MIGRATION_001})
runner.add (create {MIGRATION_002})
runner.migrate  -- Applies all pending migrations

-- Rollback if needed
runner.rollback      -- Undo last migration
runner.rollback_all  -- Undo all migrations
runner.reset         -- Rollback all then migrate all
```

## PRAGMA Configuration

```eiffel
-- Apply production settings
db.pragma.apply_production  -- WAL mode, NORMAL sync, FK enabled

-- Or configure individually
db.pragma.set_journal_mode_wal
db.pragma.set_synchronous_normal
db.pragma.enable_foreign_keys
db.pragma.set_cache_size (10000)
db.pragma.set_busy_timeout (5000)
```

## Schema Introspection

```eiffel
create schema.make (db)

-- List tables and views
across schema.tables as t loop print (t) end
across schema.views as v loop print (v) end

-- Get column details
across schema.columns ("users") as c loop
    print (c.name + ": " + c.column_type)
    if c.is_primary_key > 0 then print (" (PK)") end
end

-- Check table existence
if schema.table_exists ("users") then ... end
```

## JSON Integration

```eiffel
-- Store JSON documents
create json_obj.make
json_obj.put_string ("Alice", "name").do_nothing
json_obj.put_integer (30, "age").do_nothing

db.execute ("CREATE TABLE profiles (data TEXT)")
db.execute ("INSERT INTO profiles VALUES ('" + json_obj.to_json_string + "')")

-- Retrieve and parse
result := db.query ("SELECT data FROM profiles")
value := (create {SIMPLE_JSON}).parse (result.first.string_value ("data"))
name := value.as_object.item ("name").as_string_32
```

## Backup Operations

```eiffel
-- Memory to file backup
create mem_db.make_memory
-- ... populate database ...
create backup.
backup.copy_memory_to_file (mem_db, "backup.db")

-- File to memory restore
create mem_db.make_memory
backup.copy_file_to_memory ("backup.db", mem_db)
```

## Current Architecture

```
SIMPLE_SQL_DATABASE           -- Main database interface
    ├── execute()             -- Command execution
    ├── query()               -- Query with results
    ├── begin_transaction()
    ├── commit() / rollback()
    ├── select_builder        -- Returns fluent SELECT builder
    ├── insert_builder        -- Returns fluent INSERT builder
    ├── update_builder        -- Returns fluent UPDATE builder
    ├── delete_builder        -- Returns fluent DELETE builder
    └── pragma                -- Returns PRAGMA config

SIMPLE_SQL_RESULT             -- Query results
    ├── rows                  -- Iterable collection
    ├── count                 -- Row count
    └── first/last            -- Direct access

SIMPLE_SQL_ROW                -- Individual row
    ├── string_value()        -- Type-safe access
    ├── integer_value()
    ├── real_value()
    ├── is_null()
    └── item([index])         -- Generic access

SIMPLE_SQL_PREPARED_STATEMENT -- Parameterized queries
    ├── bind_text/integer/real/null()
    ├── execute_query()
    ├── execute_modify()
    └── reset()

SIMPLE_SQL_SELECT_BUILDER     -- Fluent SELECT
SIMPLE_SQL_INSERT_BUILDER     -- Fluent INSERT
SIMPLE_SQL_UPDATE_BUILDER     -- Fluent UPDATE
SIMPLE_SQL_DELETE_BUILDER     -- Fluent DELETE

SIMPLE_SQL_SCHEMA             -- Schema introspection
    ├── tables / views
    ├── columns()
    ├── indexes()
    ├── foreign_keys()
    └── table_exists()

SIMPLE_SQL_MIGRATION          -- Migration base class
SIMPLE_SQL_MIGRATION_RUNNER   -- Migration executor
    ├── migrate() / rollback()
    ├── migrate_to()
    └── reset()

SIMPLE_SQL_ERROR              -- Error details
SIMPLE_SQL_ERROR_CODE         -- Error constants
SIMPLE_SQL_PRAGMA_CONFIG      -- PRAGMA settings
SIMPLE_SQL_BATCH              -- Bulk operations
SIMPLE_SQL_BACKUP             -- Backup utilities
```

## Testing

Comprehensive test suite using EiffelStudio AutoTest framework (131 tests):

| Test Class | Tests | Coverage |
|------------|-------|----------|
| TEST_SIMPLE_SQL | 12 | Core functionality |
| TEST_SIMPLE_SQL_BACKUP | 5 | Backup operations |
| TEST_SIMPLE_SQL_JSON | 5 | JSON integration |
| TEST_SIMPLE_SQL_PREPARED_STATEMENT | 10 | Prepared statements, binding |
| TEST_SIMPLE_SQL_ERROR | 20 | Error handling, error codes |
| TEST_SIMPLE_SQL_PRAGMA_CONFIG | 18 | PRAGMA configuration |
| TEST_SIMPLE_SQL_BATCH | 12 | Batch operations |
| TEST_SIMPLE_SQL_QUERY_BUILDERS | 34 | SELECT/INSERT/UPDATE/DELETE builders |
| TEST_SIMPLE_SQL_SCHEMA | 11 | Schema introspection |
| TEST_SIMPLE_SQL_MIGRATION | 11 | Migration framework |

All tests include proper setup/teardown with `on_prepare`/`on_clean` for isolated execution.

## Roadmap to World-Class

### ✅ Phase 1: Core Excellence (COMPLETED)

**Prepared Statements & SQL Injection Prevention**
- ✅ Parameterized queries with `?` placeholders
- ✅ Automatic escaping for dynamic SQL
- ✅ Type-safe parameter binding

**Enhanced Error Handling**
- ✅ Detailed error context with query text
- ✅ Error categorization (constraint, syntax, etc.)
- ✅ Error code constants

**PRAGMA Configuration**
- ✅ Journal mode, synchronous mode, foreign keys
- ✅ Cache size, busy timeout
- ✅ Preset configurations

**Batch Operations**
- ✅ Transaction-wrapped batch execution
- ✅ Bulk insert optimization

### ✅ Phase 2: Developer Experience (COMPLETED)

**Schema Migration Framework**
- ✅ Version-controlled schema changes
- ✅ Up/down migration support
- ✅ Automatic rollback on failure
- ✅ PRAGMA user_version tracking

**Query Builder API**
- ✅ Fluent SELECT/INSERT/UPDATE/DELETE builders
- ✅ Full WHERE clause support
- ✅ JOIN, ORDER BY, GROUP BY, LIMIT/OFFSET

**Schema Introspection**
- ✅ Table/view enumeration
- ✅ Column, index, foreign key details
- ✅ Schema version tracking

### Phase 3: Advanced Features (Next Priority)

**Connection Pooling**
- Multi-threaded database access
- Connection lifecycle management
- Pool size configuration
- Connection health monitoring

**Performance Optimization**
- Query result streaming for large datasets
- Lazy loading of result rows
- Cursor-based iteration
- Index suggestion analysis

**ORM-Like Features**
- Object-to-table mapping
- Automatic CRUD generation
- Relationship handling (1:1, 1:N, N:M)
- Lazy loading of related objects

### Phase 4: Specialized Features

**Full-Text Search Integration**
- FTS5 module integration
- Index management
- Relevance ranking
- Highlight/snippet generation

**BLOB Handling**
- Streaming large binary data
- Incremental read/write
- Memory-efficient processing
- Direct file ↔ BLOB operations

**Advanced JSON Support**
- JSON path queries (leveraging SQLite json_extract)
- JSON aggregation functions
- Schema validation integration
- Partial updates with JSON Patch/Merge Patch

**Spatial Data Support**
- SpatiaLite extension integration
- Geometric query support
- GIS operations

**Observability & Monitoring**
- Query performance tracking
- Slow query logging
- Connection pool metrics
- Cache hit rates
- Automatic EXPLAIN QUERY PLAN

### Phase 4: Enterprise Features (Future)

**Multi-Database Support**
- Database abstraction layer
- PostgreSQL adapter
- MySQL adapter
- Unified API across databases

**Replication & Sync**
- Master-slave replication
- Conflict resolution
- Offline-first synchronization
- Change data capture (CDC)

**Security Enhancements**
- Encrypted database support (SQLCipher)
- Row-level security
- Audit logging
- Data masking/anonymization

**Advanced Transactions**
- Savepoint support
- Nested transactions
- Distributed transactions (2PC)
- MVCC configuration

## Typical Use Cases

1. **Desktop Applications** - Local data storage with JSON documents
2. **Configuration Management** - App settings, user preferences
3. **Caching Layer** - High-speed data cache with persistence
4. **Testing** - In-memory databases for fast test execution
5. **Data Export/Import** - Memory ↔ File backup for portability
6. **Embedded Systems** - Lightweight data persistence
7. **Development Tools** - Schema prototyping, data exploration

## Specialized Use Cases

1. **Time-Series Data** - Efficient storage with appropriate indexes
2. **Document Store** - JSON document storage with SQLite as backend
3. **Message Queues** - Durable queue implementation
4. **Analytics** - Local OLAP with window functions
5. **Mobile Sync** - Offline-capable mobile app backend
6. **Logging Systems** - Structured log storage and querying
7. **Session Management** - Web session persistence
8. **Feature Flags** - Dynamic configuration with real-time updates

## Dependencies

- EiffelStudio 25.02+
- SQLite3 library (included with EiffelStudio)
- SIMPLE_JSON library (for JSON integration)

## License

MIT License - See LICENSE file for details

## Contributing

Contributions welcome! Please ensure:
- All new code includes comprehensive contracts
- Test coverage for all features
- Following established naming conventions
- Documentation for public APIs

## Status

**Current Version:** 0.2
**Stability:** Beta - Core API stable
**Production Ready:** Phase 1 & 2 complete with 131 passing tests
**Test Coverage:** Comprehensive test suite covering all implemented features

---

**Built with Eiffel's Design by Contract principles for maximum reliability.**
