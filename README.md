# SIMPLE_SQL

**High-level SQLite API for Eiffel**

A production-quality, easy-to-use wrapper around the Eiffel SQLite3 library, providing a clean, intuitive interface for database operations with comprehensive error handling and Design by Contract principles.

## Features

### ✅ Implemented (v0.3)

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

**Enhanced Error Handling (NEW):**
- Structured error objects with context (`SIMPLE_SQL_ERROR`)
- Enumerated SQLite error codes (`SIMPLE_SQL_ERROR_CODE`)
- Both primary and extended error codes
- Human-readable error names
- Error category queries (is_constraint_violation, is_busy, is_readonly, etc.)
- Specific constraint type detection (unique, primary key, foreign key, check, not null)

**Prepared Statements (NEW):**
- Parameterized queries preventing SQL injection
- Parameter binding by index: `bind_integer(1, value)`
- Parameter binding by name: `bind_text_by_name(":name", value)`
- Support for INTEGER, REAL, TEXT, BLOB, and NULL types
- Statement reset for efficient reuse
- Automatic type conversion and escaping

**PRAGMA Configuration (NEW):**
- Named configuration presets: `make_wal`, `make_performance`, `make_safe`
- WAL mode for improved concurrency
- Synchronous mode control
- Cache size configuration
- Busy timeout settings
- Foreign key enforcement
- Memory-mapped I/O configuration

**Batch Operations:**
- Automatic transaction wrapping for bulk operations
- `insert_many()` for bulk inserts
- `execute_many()` for multiple SQL statements
- Individual `insert()`, `update()`, `delete()` with auto-commit control
- Manual transaction control with `begin()`, `commit()`, `rollback()`

**Fluent Query Builder (NEW):**
- Chainable SELECT, INSERT, UPDATE, DELETE builders
- Type-safe value binding with automatic escaping
- WHERE clauses with AND/OR chaining
- JOIN support (INNER, LEFT, CROSS)
- GROUP BY, HAVING, ORDER BY, LIMIT, OFFSET
- Raw SQL expressions for complex cases
- Direct execution or SQL string generation

**Schema Introspection (NEW):**
- Query table/view names and existence
- Column metadata (name, type, nullability, default, primary key)
- Index information (columns, uniqueness, origin)
- Foreign key constraints with ON UPDATE/DELETE actions
- PRAGMA user_version for migration tracking

**Migration System (NEW):**
- Version-controlled schema changes via PRAGMA user_version
- Up/down migration support
- Automatic transaction wrapping per migration
- Rollback on failure
- Migrate to specific version or latest
- Reset capability (rollback all, migrate all)

**Advanced Features:**
- Memory ↔ File backup utilities
- JSON integration with SIMPLE_JSON library
- Change tracking (affected row counts)
- Comprehensive test suite with 100% coverage goal

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

-- Insert data
db.execute ("INSERT INTO users (name, age) VALUES ('Alice', 30)")

-- Query data
result := db.query ("SELECT * FROM users WHERE age > 25")
across result.rows as ic loop
    print (ic.string_value ("name"))
    print (ic.integer_value ("age"))
end

-- Transactions
db.begin_transaction
db.execute ("INSERT INTO users VALUES (2, 'Bob', 25)")
db.commit

-- Cleanup
db.close
```

## Prepared Statements

```eiffel
-- Create prepared statement (prevents SQL injection)
stmt := db.prepare ("INSERT INTO users (name, age) VALUES (?, ?)")

-- Bind by index (1-based)
stmt.bind_text (1, "Alice")
stmt.bind_integer (2, 30)
stmt.execute

-- Reuse with new values
stmt.reset
stmt.bind_text (1, "Bob")
stmt.bind_integer (2, 25)
stmt.execute

-- Named parameters
stmt := db.prepare ("SELECT * FROM users WHERE name = :name")
stmt.bind_text_by_name (":name", "Alice")
result := stmt.execute_returning_result
```

## Error Handling

```eiffel
db.execute ("INSERT INTO users (id, name) VALUES (1, 'Alice')")
db.execute ("INSERT INTO users (id, name) VALUES (1, 'Bob')")  -- Duplicate!

if db.has_error then
    if db.is_constraint_error then
        print ("Constraint violation: " + db.last_error_message)
    end

    -- Detailed error information
    if attached db.last_structured_error as err then
        print (err.full_description)
        if err.is_unique_violation then
            print ("Duplicate key detected")
        end
    end
end
```

## PRAGMA Configuration

```eiffel
-- WAL mode for better concurrency
create config.make_wal
config.apply (db)

-- Performance optimized (WAL + larger cache + memory-mapped I/O)
create config.make_performance
config.apply (db)

-- Maximum safety (synchronous FULL + delete journal)
create config.make_safe
config.apply (db)

-- Custom configuration
create config.make_custom
config.set_journal_mode (config.Journal_wal)
config.set_cache_size (10000)
config.set_foreign_keys (True)
config.apply (db)
```

## Batch Operations

```eiffel
-- Bulk inserts with automatic transaction
create batch.make (db)
batch.insert_many ("users", <<"name", "age">>, <<
    <<"Alice", "30">>,
    <<"Bob", "25">>,
    <<"Charlie", "35">>
>>)

-- Multiple operations in one transaction
batch.begin
batch.insert ("logs", <<"event", "timestamp">>, <<"login", "2025-01-15">>)
batch.insert ("logs", <<"event", "timestamp">>, <<"action", "2025-01-15">>)
batch.update ("users", "last_login = ?", <<"2025-01-15">>, "id = 1")
batch.commit
```

## Fluent Query Builder

```eiffel
-- SELECT with fluent API
result := db.select_builder
    .select_columns (<<"name", "age", "email">>)
    .from_table ("users")
    .where_equals ("status", "active")
    .and_where ("age > 18")
    .order_by ("name")
    .limit (10)
    .execute

-- Complex SELECT with joins
result := db.select_builder
    .select_column ("u.name")
    .select_column_as ("COUNT(o.id)", "order_count")
    .from_table_as ("users", "u")
    .left_join ("orders o", "o.user_id = u.id")
    .group_by ("u.id")
    .having ("COUNT(o.id) > 5")
    .execute

-- INSERT with builder
rows := db.insert_builder
    .into ("users")
    .columns_list (<<"name", "age", "email">>)
    .values (<<"Alice", 30, "alice@example.com">>)
    .execute

-- Get last inserted ID
id := db.insert_builder
    .into ("users")
    .set ("name", "Bob")
    .set ("age", 25)
    .execute_returning_id

-- UPDATE with builder
count := db.update_builder
    .table ("users")
    .set ("status", "inactive")
    .set ("updated_at", "2025-01-15")
    .where_equals ("last_login", Void)  -- WHERE last_login IS NULL
    .execute

-- Increment/decrement
count := db.update_builder
    .table ("products")
    .decrement_by ("stock", 1)
    .where_id (product_id)
    .execute

-- DELETE with builder
count := db.delete_builder
    .from_table ("sessions")
    .where ("expires_at < datetime('now')")
    .execute

-- Generate SQL without executing
sql := db.select_builder
    .select_all
    .from_table ("users")
    .where_in ("id", <<1, 2, 3>>)
    .to_sql
-- Result: "SELECT * FROM users WHERE id IN (1, 2, 3)"
```

## Schema Introspection

```eiffel
-- Get all tables
schema := db.schema
across schema.tables as t loop
    print (t)
end

-- Check if table exists
if schema.table_exists ("users") then
    -- Get detailed table info
    if attached schema.table_info ("users") as info then
        print ("Table: " + info.name + " (" + info.column_count.out + " columns)")

        -- Inspect columns
        across info.columns as col loop
            print ("  " + col.description)
            -- Output: "id INTEGER PRIMARY KEY NOT NULL"
            --         "name TEXT"
            --         "age INTEGER DEFAULT 0"
        end

        -- Check primary key
        across info.primary_key_columns as pk loop
            print ("Primary key: " + pk.name)
        end

        -- Inspect indexes
        across info.indexes as idx loop
            print ("Index: " + idx.description)
        end

        -- Inspect foreign keys
        across info.foreign_keys as fk loop
            print ("FK: " + fk.description)
        end
    end
end

-- Get column names only
columns := schema.column_names ("users")

-- Check schema version (for migrations)
print ("Current version: " + schema.user_version.out)
```

## Migration System

```eiffel
-- Define a migration
class MY_MIGRATION_001
inherit SIMPLE_SQL_MIGRATION

feature
    version: INTEGER = 1
    description: STRING_8 = "Create users table"

    up (db: SIMPLE_SQL_DATABASE)
        do
            db.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL)")
            db.execute ("CREATE INDEX idx_users_name ON users (name)")
        end

    down (db: SIMPLE_SQL_DATABASE)
        do
            db.execute ("DROP INDEX idx_users_name")
            db.execute ("DROP TABLE users")
        end
end

-- Run migrations
create runner.make (db)
runner.add (create {MY_MIGRATION_001})
runner.add (create {MY_MIGRATION_002})
runner.add (create {MY_MIGRATION_003})

-- Check status
print ("Current version: " + runner.current_version.out)
print ("Latest version: " + runner.latest_version.out)
print ("Pending: " + runner.pending_migrations.count.out)

-- Migrate to latest
if runner.migrate then
    print ("Migration successful!")
else
    print ("Migration failed: " + runner.last_error)
end

-- Migrate to specific version
runner.migrate_to (2)

-- Rollback last migration
runner.rollback

-- Rollback all
runner.rollback_all

-- Fresh start (rollback all, then migrate all)
runner.reset
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
    ├── execute()              -- Command execution
    ├── query()                -- Query with results
    ├── prepare()              -- Create prepared statement
    ├── select_builder()       -- Create SELECT builder (NEW)
    ├── insert_builder()       -- Create INSERT builder (NEW)
    ├── update_builder()       -- Create UPDATE builder (NEW)
    ├── delete_builder()       -- Create DELETE builder (NEW)
    ├── schema()               -- Schema introspection (NEW)
    ├── begin_transaction()
    ├── commit()
    ├── rollback()
    ├── has_error              -- Error status
    ├── last_structured_error  -- Full error details
    └── error_codes            -- Error code constants

SIMPLE_SQL_RESULT             -- Query results
    ├── rows                   -- Iterable collection
    ├── count                  -- Row count
    └── first/last             -- Direct access

SIMPLE_SQL_ROW                -- Individual row
    ├── string_value()         -- Type-safe access
    ├── integer_value()
    ├── real_value()
    ├── is_null()
    └── item([index])          -- Generic access

SIMPLE_SQL_SELECT_BUILDER     -- Fluent SELECT (NEW)
    ├── select_column()        -- Add column
    ├── from_table()           -- Set table
    ├── where() / and_where()  -- Conditions
    ├── join() / left_join()   -- Joins
    ├── group_by() / having()  -- Grouping
    ├── order_by() / limit()   -- Ordering
    ├── execute()              -- Run query
    └── to_sql()               -- Generate SQL

SIMPLE_SQL_INSERT_BUILDER     -- Fluent INSERT (NEW)
    ├── into()                 -- Set table
    ├── columns_list()         -- Set columns
    ├── values()               -- Add row values
    ├── set()                  -- Column-value pair
    ├── execute()              -- Run insert
    └── execute_returning_id() -- Get last ID

SIMPLE_SQL_UPDATE_BUILDER     -- Fluent UPDATE (NEW)
    ├── table()                -- Set table
    ├── set()                  -- Column = value
    ├── set_expression()       -- Raw SQL expression
    ├── increment() / decrement()
    ├── where() / and_where()
    └── execute()

SIMPLE_SQL_DELETE_BUILDER     -- Fluent DELETE (NEW)
    ├── from_table()           -- Set table
    ├── where() / and_where()
    └── execute()

SIMPLE_SQL_SCHEMA             -- Schema introspection (NEW)
    ├── tables() / views()     -- List names
    ├── table_exists()         -- Check existence
    ├── table_info()           -- Full table details
    ├── columns()              -- Column list
    ├── indexes()              -- Index list
    ├── foreign_keys()         -- FK list
    └── user_version           -- Migration version

SIMPLE_SQL_TABLE_INFO         -- Table metadata (NEW)
    ├── name / table_type
    ├── columns                -- SIMPLE_SQL_COLUMN_INFO list
    ├── indexes                -- SIMPLE_SQL_INDEX_INFO list
    ├── foreign_keys           -- SIMPLE_SQL_FOREIGN_KEY_INFO list
    └── sql                    -- Original CREATE statement

SIMPLE_SQL_MIGRATION          -- Migration base class (NEW)
    ├── version                -- Migration number
    ├── description            -- Human-readable
    ├── up()                   -- Apply changes
    └── down()                 -- Revert changes

SIMPLE_SQL_MIGRATION_RUNNER   -- Migration executor (NEW)
    ├── add()                  -- Register migration
    ├── migrate()              -- Run all pending
    ├── migrate_to()           -- Target version
    ├── rollback()             -- Undo last
    ├── rollback_all()         -- Undo all
    └── reset()                -- Fresh start

SIMPLE_SQL_PREPARED_STATEMENT -- Parameterized queries
    ├── bind_integer()         -- Bind by index
    ├── bind_text()
    ├── bind_real()
    ├── bind_null()
    ├── bind_*_by_name()       -- Bind by name
    ├── execute()
    └── reset()                -- Reuse statement

SIMPLE_SQL_BATCH              -- Bulk operations
    ├── insert_many()          -- Bulk insert
    ├── execute_many()         -- Multiple statements
    ├── begin() / commit()     -- Transaction control
    └── rollback()

SIMPLE_SQL_ERROR              -- Structured error
    ├── code / extended_code   -- Error codes
    ├── message / sql          -- Context
    ├── is_constraint_violation
    ├── is_unique_violation
    └── full_description()

SIMPLE_SQL_ERROR_CODE         -- Error constants
    ├── ok, error, busy, locked
    ├── constraint, readonly
    ├── constraint_unique      -- Extended codes
    └── name()                 -- Human-readable

SIMPLE_SQL_PRAGMA_CONFIG      -- Configuration
    ├── make_wal               -- WAL mode preset
    ├── make_performance       -- Performance preset
    ├── make_safe              -- Safety preset
    └── apply()                -- Apply to database

SIMPLE_SQL_BACKUP             -- Backup utilities
    ├── copy_memory_to_file()
    └── copy_file_to_memory()
```

## Testing

Comprehensive test suite using EiffelStudio AutoTest framework:
- `TEST_SIMPLE_SQL` - Core functionality (12 tests)
- `TEST_SIMPLE_SQL_BACKUP` - Backup operations (5 tests)
- `TEST_SIMPLE_SQL_JSON` - JSON integration (5 tests)

All tests include proper setup/teardown with `on_prepare`/`on_clean` for isolated execution.

## Roadmap to World-Class

### ✅ Phase 1: Core Excellence (COMPLETE)

**Enhanced Error Handling** ✅
- Structured error objects with full context
- Enumerated SQLite error codes (primary + extended)
- Constraint violation detection and categorization

**Prepared Statements** ✅
- SQL injection prevention via parameterized queries
- Binding by index and by name
- Statement reuse with reset

**PRAGMA Configuration** ✅
- WAL mode and journal mode control
- Synchronous mode, cache size, busy timeout
- Named presets for common configurations

**Batch Operations** ✅
- Bulk inserts with automatic transactions
- Multiple statement execution
- Transaction control

### ✅ Phase 2: Developer Experience (COMPLETE)

**Fluent Query Builder** ✅
- Chainable SELECT/INSERT/UPDATE/DELETE builders
- Type-safe value binding with automatic escaping
- WHERE, JOIN, GROUP BY, ORDER BY, LIMIT support
- Raw SQL expressions for complex cases

**Schema Introspection** ✅
- Table/view listing and existence checking
- Column metadata (name, type, constraints)
- Index and foreign key introspection
- PRAGMA user_version access

**Migration System** ✅
- Version-controlled schema changes
- Up/down migration support
- Automatic transaction wrapping
- Rollback on failure
- Migrate to specific version or latest

### Phase 3: Advanced Features (Next)

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

**Current Version:** 0.3
**Stability:** Beta - Core API stable
**Production Ready:** Core features production-ready, advanced features in development

---

**Built with Eiffel's Design by Contract principles for maximum reliability.**
