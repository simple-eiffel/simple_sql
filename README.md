<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_ library logo" width="400">
</p>

# SIMPLE_SQL

**High-level SQLite API for Eiffel**

A production-quality, easy-to-use wrapper around the Eiffel SQLite3 library, providing a clean, intuitive interface for database operations with comprehensive error handling and Design by Contract principles.

## The Elevator Pitch

SIMPLE_SQL isn't just another database wrapper - it's an API designed by *building real applications*.

Most libraries are designed top-down: imagine what features users might need, implement them, hope they're useful. SIMPLE_SQL is designed bottom-up: we build realistic mock applications (TODO list, CPM project scheduler, etc.) and let the friction guide API improvements.

**The result?** An API that eliminates boilerplate, not one that creates it.

```eiffel
-- Instead of this (5 lines of ceremony):
l_stmt := db.prepare ("INSERT INTO users (name, age) VALUES (?, ?)")
l_stmt.bind_text (1, "Alice")
l_stmt.bind_integer (2, 30)
l_stmt.execute

-- You write this (1 line that just works):
db.execute_with_args ("INSERT INTO users (name, age) VALUES (?, ?)", <<"Alice", 30>>)
```

Every convenience method in SIMPLE_SQL exists because a real application needed it, not because we thought it might be useful someday.

## Mock-Driven Development

The `src/` directory contains mock applications that serve dual purposes:

1. **Demonstrate** how to use SIMPLE_SQL in realistic scenarios
2. **Stress-test** the API to expose friction and drive improvements

| Mock App | Domain | Scale | Key Friction Exposed | API Improvements Driven |
|----------|--------|-------|---------------------|------------------------|
| `todo_app` | Task management | Basic CRUD | Query builder basics, result handling | Initial patterns, fluent API |
| `cpm_app` | Project scheduling | 51 activities, 65 dependencies | Complex relationships, repeated queries | `execute_with_args`, `query_with_args` |
| `habit_tracker` | Time-series data | Daily tracking, streaks, analytics | Aggregations, date handling, soft deletes | Streaming cursors, date utilities |
| `dms` | Document management | Hierarchical folders, versioning, FTS | N+1 queries, pagination, audit trails | **Eager loading**, **soft delete scopes**, **pagination builder**, **N+1 detection** |
| `wms` | Warehouse/Inventory | Stock, reservations, movements | **Optimistic locking**, **atomic multi-table ops**, **upsert**, **concurrent access** | **Atomic operations**, **versioned updates**, **conditional decrements** |

### What Each Mock App Teaches

**TODO App** - Start here. Shows basic CRUD patterns: creating tables, inserting data, querying with the fluent builder, handling results.

**CPM App** - Complex relationships. A real Critical Path Method scheduler with 51 construction activities and 65 dependencies. Demonstrates parameterized queries, transaction handling, and graph algorithms over relational data.

**Habit Tracker** - Time-series patterns. Daily habit tracking with streak calculations, completion rates, and trend analysis. Shows aggregation queries, date handling, and soft delete patterns.

**DMS (Document Management System)** - Enterprise patterns. Hierarchical folders, document versioning, comments, tags (many-to-many), sharing permissions, FTS5 search, cursor-based pagination, and full audit trails. This mock exposed the most API friction and drove the most improvements.

**WMS (Warehouse Management System)** - Concurrency patterns. Stock management with optimistic locking (version columns), reservation system with expiry, atomic stock transfers between locations, movement audit trails. This mock exposes friction around concurrent access and multi-table atomic operations - key areas for Phase 6 improvements.

Each mock application has its own test suite. When we add API improvements based on mock app friction, we add tests for both the new API *and* verify the mock app benefits.

## Features

### ✅ Implemented (v1.0)

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

**Prepared Statements:**
- Parameterized queries preventing SQL injection
- Parameter binding by index: `bind_integer(1, value)`
- Parameter binding by name: `bind_text_by_name(":name", value)`
- Support for INTEGER, REAL, TEXT, BLOB, and NULL types
- Statement reset for efficient reuse
- Automatic type conversion and escaping

**Convenience Methods (NEW - from mock app development):**
- `execute_with_args(sql, args)` - Execute with auto-bound parameters
- `query_with_args(sql, args)` - Query with auto-bound parameters
- Automatic type detection: INTEGER, INTEGER_64, REAL_64, STRING, BOOLEAN, MANAGED_POINTER, Void (NULL)
- Eliminates manual prepared statement binding boilerplate

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

**Query Result Streaming (NEW):**
- Lazy cursor for row-by-row iteration (`SIMPLE_SQL_CURSOR`)
- Memory-efficient processing of large result sets
- Callback-based streaming (`SIMPLE_SQL_RESULT_STREAM`)
- Early termination support (stop processing when condition met)
- `for_each`, `collect_first`, `count_rows`, `first_row`, `exists` operations
- Full `across` loop integration

**Advanced Features:**
- Memory ↔ File backup utilities
- JSON integration with SIMPLE_JSON library
- **JSON1 Extension Support** with validation, path queries, modification, aggregation (NEW)
- Change tracking (affected row counts)
- **FTS5 Full-Text Search** with BM25 ranking, Boolean queries, and special character handling
- **BLOB Handling** with file I/O, hex encoding, and named parameter binding
- **Automatic Audit/Change Tracking** with trigger-based change capture and JSON storage
- **Repository Pattern** with generic CRUD operations, find_all, find_by_id, find_where, pagination
- **Vector Embeddings** for ML/AI with similarity search, K-nearest neighbors, cosine/Euclidean distance
- **Online Backup API** with progress callbacks, incremental backup, export/import (CSV, JSON, SQL)
- **Eager Loading** to eliminate N+1 query problems with `.include()` API (NEW)
- **Soft Delete Scopes** with `.active_only`, `.deleted_only`, `.with_deleted` (NEW)
- **Pagination Builder** for cursor-based pagination (NEW)
- **N+1 Query Detection** with runtime monitoring and warnings (NEW)
- **Atomic Operations (Phase 6)** for concurrency-safe database updates (NEW)
  - `atomic(agent)` - Transaction wrapper with auto-rollback on failure
  - `update_versioned(table, id, version, set, args)` - Optimistic locking
  - `upsert(table, columns, values, conflict_cols)` - INSERT ON CONFLICT UPDATE
  - `decrement_if(table, col, amount, where, args)` - Conditional atomic decrement
  - `increment_if(table, col, amount, where, args)` - Conditional atomic increment
- Comprehensive test suite with 500+ tests (100% passing)

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

## Parameterized Convenience Methods

The easiest way to work with parameters - automatic type detection and binding:

```eiffel
-- Execute with parameters (INSERT, UPDATE, DELETE)
db.execute_with_args ("INSERT INTO users (name, age, score) VALUES (?, ?, ?)",
    <<"Alice", 30, 95.5>>)

-- Query with parameters
result := db.query_with_args ("SELECT * FROM users WHERE age > ? AND status = ?",
    <<21, "active">>)

-- Supported types (auto-detected):
-- INTEGER, INTEGER_64, REAL_64, STRING, BOOLEAN, MANAGED_POINTER (BLOB), Void (NULL)
db.execute_with_args ("INSERT INTO data (int_col, str_col, null_col) VALUES (?, ?, ?)",
    <<42, "text", Void>>)  -- Void becomes NULL

-- Works great with manifest arrays
db.execute_with_args ("UPDATE products SET price = ?, stock = ? WHERE id = ?",
    <<24.99, 100, product_id>>)
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

## Query Result Streaming

```eiffel
-- Cursor iteration (memory-efficient for large datasets)
across db.query_cursor ("SELECT * FROM large_table") as ic loop
    print (ic.string_value ("name"))
    print (ic.integer_value ("age"))
end

-- Manual cursor control
cursor := db.query_cursor ("SELECT * FROM users")
from cursor.start until cursor.after loop
    row := cursor.item
    -- process row
    cursor.forth
end
cursor.close

-- Stream with callback (process each row, return True to stop)
db.query_stream ("SELECT * FROM logs", agent process_log_entry)

-- Advanced streaming operations
stream := db.create_stream ("SELECT * FROM events")
stream.for_each (agent handle_event)           -- Process all
stream.for_each_do (agent print_event)         -- Process all (no early stop)
recent := stream.collect_first (100)           -- Get first 100 rows
total := stream.count_rows                     -- Count without loading all
if stream.exists then ... end                  -- Check if any rows match
first := stream.first_row                      -- Get first row only

-- Prepared statement streaming
stmt := db.prepare ("SELECT * FROM users WHERE age > ?")
stmt.bind_integer (1, 21)
cursor := stmt.execute_cursor
stream := stmt.execute_stream

-- SELECT builder streaming
db.select_builder
    .from_table ("users")
    .where ("active = 1")
    .for_each (agent process_user)
```

## JSON Integration

### Basic JSON Storage (SIMPLE_JSON library)

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

### Advanced JSON Operations (SQLite JSON1 Extension)

The JSON1 extension provides powerful JSON manipulation directly in SQL:

```eiffel
-- Get JSON helper
json := db.json

-- Validation
if json.is_valid_json ("{%"name%":%"Alice%"}") then
    print ("Valid JSON%N")
end

-- Type checking
json_type := json.json_type ("{%"age%":30}", "$.age")  -- Returns "integer"

-- Path extraction
l_json := "{%"user%":{%"name%":%"Alice%",%"age%":30}}"
name := json.extract (l_json, "$.user.name")           -- Returns "Alice"
age := json.extract (l_json, "$.user.age")             -- Returns "30"

-- Extract array elements
l_json := "{%"colors%\":[%\"red%\",%\"green%\",%\"blue%\"]}"
color := json.extract (l_json, "$.colors[0]")          -- Returns "red"

-- Modification operations
l_json := "{%\"a%\":1}"
l_json := json.json_set (l_json, "$.b", 2)             -- {" a":1,"b":2}
l_json := json.json_insert (l_json, "$.c", 3)          -- {" a":1,"b":2,"c":3}
l_json := json.json_replace (l_json, "$.a", 99)        -- {" a":99,"b":2,"c":3}
l_json := json.json_remove (l_json, "$.c")             -- {" a":99,"b":2}

-- Create JSON from Eiffel values
l_array := json.json_array_from_values (<<1, "two", 3.0>>)
-- Returns: [1,"two",3.0]

l_object := json.json_object_from_pairs (<<
    ["name", "Alice"],
    ["age", 30]
>>)
-- Returns: {"name":"Alice","age":30}

-- Aggregate database values to JSON
db.execute ("CREATE TABLE users (name TEXT, age INTEGER)")
db.execute ("INSERT INTO users VALUES ('Alice', 30)")
db.execute ("INSERT INTO users VALUES ('Bob', 25)")

-- Create JSON array from column
l_names := json.aggregate_to_array ("users", "name", Void)
-- Returns: ["Alice","Bob"]

-- Create JSON array with WHERE clause
l_adult_names := json.aggregate_to_array ("users", "name", "age >= 18")

-- Create JSON object from key-value columns
db.execute ("CREATE TABLE settings (key TEXT, value TEXT)")
db.execute ("INSERT INTO settings VALUES ('theme', 'dark')")
db.execute ("INSERT INTO settings VALUES ('lang', 'en')")
l_settings := json.aggregate_to_object ("settings", "key", "value", Void)
-- Returns: {"theme":"dark","lang":"en"}

-- Use JSON functions in queries
db.execute ("CREATE TABLE documents (data TEXT)")
db.execute ("INSERT INTO documents VALUES ('{%\"user%\":{%\"name%\":%\"Alice%\"}}')\" )

result := db.query ("SELECT json_extract(data, '$.user.name') as name FROM documents")
name := result.first.string_value ("name")  -- "Alice"

-- Modify JSON in UPDATE statements
db.execute ("UPDATE documents SET data = json_set(data, '$.user.age', 30)")
```

## FTS5 Full-Text Search

```eiffel
-- Check if FTS5 is available
create fts5.make (db)
if fts5.is_fts5_available then
    -- Create FTS5 virtual table
    fts5.create_table ("documents", <<"title", "content">>)

    -- Insert searchable text
    fts5.insert ("documents", <<"title", "content">>, <<
        "SQLite Guide", "Learn how to use SQLite effectively"
    >>)

    -- Simple search
    result := fts5.search ("documents", "SQLite")

    -- Boolean search with query builder
    result := fts5.query_builder ("documents")
        .match_all (<<"SQLite", "Guide">>)      -- AND query
        .with_rank                               -- Include BM25 score
        .execute

    -- Phrase search (handles special characters like apostrophes)
    result := fts5.search ("documents", "O'Brien's guide")

    -- Get search suggestions
    result := fts5.query_builder ("documents")
        .match_any (<<"database", "SQL", "query">>)  -- OR query
        .not_matching ("tutorial")                    -- Exclude results
        .order_by_rank                                -- Best matches first
        .limit (10)
        .execute
end
```

## Automatic Change Tracking (Audit)

Automatically track all changes to database tables using triggers:

```eiffel
-- Enable auditing for a table
audit := db.audit
audit.enable_for_table ("users")

-- Changes are now automatically tracked
db.execute ("INSERT INTO users (id, name, age) VALUES (1, 'Alice', 30)")
db.execute ("UPDATE users SET age = 31 WHERE id = 1")
db.execute ("DELETE FROM users WHERE id = 1")

-- Query audit history for a specific record
changes := audit.get_changes_for_record ("users", 1)
across changes.rows as ic loop
    io.put_string (ic.item.string_value ("operation"))  -- "INSERT", "UPDATE", "DELETE"
    io.put_string (ic.item.string_value ("timestamp"))  -- ISO 8601 timestamp
    io.put_string (ic.item.string_value ("new_values")) -- JSON of new values
end

-- Query recent changes
recent := audit.get_latest_changes ("users", 10)  -- Last 10 changes

-- Query by operation type
inserts := audit.get_changes_by_operation ("users", "INSERT")
updates := audit.get_changes_by_operation ("users", "UPDATE")
deletes := audit.get_changes_by_operation ("users", "DELETE")

-- Query by time range
changes_today := audit.get_changes_in_range ("users", 
    "2025-01-01 00:00:00", "2025-01-01 23:59:59")

-- Analyze what fields changed
changed_fields := audit.get_changed_fields ("users", audit_id)
-- Returns ARRAY [STRING_32] of field names that changed

-- Disable auditing (removes triggers, preserves history)
audit.disable_for_table ("users")

-- Drop audit table (WARNING: deletes all history)
audit.drop_audit_table ("users")
```

**Features:**
- Automatic INSERT/UPDATE/DELETE tracking via SQLite triggers
- JSON storage of old and new values
- ISO 8601 timestamps
- Field-level change detection
- Query by record, operation type, or time range
- Immutable audit trail

## Eager Loading (N+1 Query Prevention)

Eliminate the N+1 query problem with declarative eager loading:

```eiffel
-- WITHOUT eager loading: N+1 problem
-- 1 query for documents + N queries for comments = disaster
docs := db.query ("SELECT * FROM documents WHERE owner_id = 1")
across docs.rows as doc loop
    comments := db.query ("SELECT * FROM comments WHERE document_id = " + doc.integer_64_value ("id").out)
    -- Process comments...
end

-- WITH eager loading: 2 queries total regardless of N
results := db.eager_loader
    .from_table ("documents")
    .include ("comments", "document_id", "id")           -- Direct FK relationship
    .include_many_to_many ("tags", "document_tags", "document_id", "tag_id")  -- M:M via junction
    .where ("owner_id = 1")
    .order_by ("updated_at")
    .limit (20)
    .execute

-- Access main rows
across results.main_rows as doc loop
    print (doc.string_value ("title"))

    -- Access related data - already loaded!
    across results.related_for ("comments", doc.integer_64_value ("id")) as comment loop
        print ("  Comment: " + comment.string_value ("body"))
    end
end

-- Check counts
print ("Total documents: " + results.main_count.out)
print ("Total comments loaded: " + results.related_count ("comments").out)
```

## Soft Delete Scopes

Automatically filter soft-deleted records without boilerplate:

```eiffel
-- Old way: Easy to forget, clutters every query
db.select_builder.from_table ("documents")
    .where ("deleted_at IS NULL")  -- Must remember this EVERY time
    .and_where ("owner_id = 1")
    .execute

-- New way: Declarative scopes
db.select_builder.from_table ("documents")
    .active_only                    -- Only non-deleted records
    .where ("owner_id = 1")
    .execute

-- Query deleted records (trash view)
db.select_builder.from_table ("documents")
    .deleted_only                   -- Only soft-deleted records
    .execute

-- Admin view: all records regardless of status
db.select_builder.from_table ("documents")
    .with_deleted                   -- Include all records
    .execute

-- Custom soft delete column (default is "deleted_at")
db.select_builder.from_table ("archived_items")
    .set_soft_delete_column ("archived_at")
    .active_only
    .execute
```

## Pagination Builder

Clean cursor-based pagination for large datasets:

```eiffel
-- Create paginator
paginator := db.paginator ("documents")
    .order_by (<<"updated_at", "id">>)  -- Must include unique column for stable ordering
    .page_size (20)
    .active_only                         -- Integrates with soft delete
    .where ("owner_id = 1")

-- Get first page
page := paginator.first_page
across page.items as doc loop
    print (doc.string_value ("title"))
end

-- Check for more pages
if page.has_more then
    print ("Next cursor: " + page.next_cursor)
end

-- Get next page using cursor
next_page := paginator.after (page.next_cursor)

-- Page information
print ("Items on page: " + page.count.out)
print ("Is last page: " + page.is_last_page.out)
```

## N+1 Query Detection

Catch N+1 problems during development:

```eiffel
-- Enable monitoring
db.enable_query_monitor

-- Run your code (e.g., render a page)
render_document_list (db)

-- Check for N+1 warnings
if attached db.query_monitor as m then
    if m.has_warnings then
        print ("!!! N+1 DETECTED !!!")
        across m.warnings as w loop
            print (w)
        end
    end

    -- Get detailed report
    print (m.report)
    -- Output:
    -- === Query Monitor Report ===
    -- Total queries: 21
    -- Unique patterns: 2
    --
    -- !!! N+1 WARNINGS !!!
    --   - N+1 detected: Query pattern executed 20+ times: SELECT * FROM comments WHERE document_id = ?
    --
    -- Top repeated patterns:
    --   20x: SELECT * FROM comments WHERE document_id = ?
    --   1x: SELECT * FROM documents WHERE owner_id = ?
end

-- Configure sensitivity
db.query_monitor.set_threshold (3)  -- Warn after 3 similar queries (default: 5)

-- Reset between tests
db.reset_query_monitor

-- Disable when done
db.disable_query_monitor
```

## Repository Pattern

Generic repository pattern for type-safe CRUD operations:

```eiffel
-- Define your entity class
class USER_ENTITY
feature
    id: INTEGER_64
    name: STRING_8
    age: INTEGER
    status: STRING_8
end

-- Create a repository by inheriting SIMPLE_SQL_REPOSITORY
class USER_REPOSITORY inherit SIMPLE_SQL_REPOSITORY [USER_ENTITY]
feature
    table_name: STRING_8 = "users"
    primary_key_column: STRING_8 = "id"

    row_to_entity (a_row: SIMPLE_SQL_ROW): USER_ENTITY
        do
            create Result.make (
                a_row.integer_value ("id").to_integer_64,
                a_row.string_value ("name").to_string_8,
                a_row.integer_value ("age"),
                a_row.string_value ("status").to_string_8
            )
        end

    entity_to_columns (a_entity: USER_ENTITY): HASH_TABLE [detachable ANY, STRING_8]
        do
            create Result.make (3)
            Result.put (a_entity.name, "name")
            Result.put (a_entity.age, "age")
            Result.put (a_entity.status, "status")
        end

    entity_id (a_entity: USER_ENTITY): INTEGER_64
        do Result := a_entity.id end
end

-- Use the repository
create repo.make (db)

-- Find all
all_users := repo.find_all
active_users := repo.find_where ("status = 'active'")

-- Find by ID
user := repo.find_by_id (42)

-- Pagination
page_1 := repo.find_all_limited (10, 0)   -- First 10
page_2 := repo.find_all_limited (10, 10)  -- Next 10

-- Ordering
sorted := repo.find_all_ordered ("name ASC")
filtered_sorted := repo.find_where_ordered ("age > 21", "age DESC")

-- Count
total := repo.count
active_count := repo.count_where ("status = 'active'")

-- Insert (returns new ID)
create new_user.make (0, "Alice", 30, "active")
new_id := repo.insert (new_user)

-- Update
user.set_age (31)
success := repo.update (user)

-- Save (insert or update based on ID)
saved_id := repo.save (user)

-- Delete
success := repo.delete (42)
deleted_count := repo.delete_where ("status = 'inactive'")
all_deleted := repo.delete_all
```

**Features:**
- Generic deferred class `SIMPLE_SQL_REPOSITORY [G]`
- Complete CRUD operations (Create, Read, Update, Delete)
- `find_all`, `find_by_id`, `find_where`, `find_first_where`
- Pagination with `find_all_limited (limit, offset)`
- Ordering with `find_all_ordered`, `find_where_ordered`
- Counting with `count`, `count_where`
- Bulk operations: `update_where`, `delete_where`, `delete_all`
- `save` for insert-or-update semantics
- `exists` check for ID existence
- Error status via `has_error`, `last_error_message`

## Vector Embeddings

Store and search vector embeddings for ML/AI applications:

```eiffel
-- Create vector store
create store.make (db, "embeddings")

-- Create vectors from arrays
create vec.make_from_array (<<0.1, 0.2, 0.3, 0.4, 0.5>>)

-- Insert with optional metadata (JSON)
id := store.insert (vec, "{%"source%": %"document.txt%", %"chunk%": 1}")

-- Retrieve by ID
if attached store.find_by_id (id) as retrieved then
    print ("Dimension: " + retrieved.dimension.out)
end

-- K-nearest neighbor search (cosine similarity)
create query.make_from_array (<<0.15, 0.25, 0.35, 0.45, 0.55>>)
results := store.find_nearest (query, 10)  -- Top 10 most similar
across results as ic loop
    print ("ID: " + ic.id.out + " Score: " + ic.score.out)
end

-- Find all vectors above similarity threshold
similar := store.find_within_threshold (query, 0.8)  -- Cosine >= 0.8

-- K-nearest by Euclidean distance
nearest := store.find_nearest_euclidean (query, 5)

-- Direct similarity calculations
create sim.make
cosine := sim.cosine_similarity (vec1, vec2)      -- -1.0 to 1.0
euclidean := sim.euclidean_distance (vec1, vec2)  -- >= 0
manhattan := sim.manhattan_distance (vec1, vec2)  -- >= 0
is_similar := sim.is_similar (vec1, vec2, 0.9)    -- Boolean check

-- Vector math operations
normalized := vec.normalized       -- Unit vector (magnitude = 1)
magnitude := vec.magnitude         -- Euclidean norm
dot := vec.dot_product (other)     -- Inner product
sum := vec.add (other)             -- Vector addition
diff := vec.subtract (other)       -- Vector subtraction
scaled := vec.scale (2.0)          -- Scalar multiplication

-- BLOB serialization for custom storage
blob := vec.to_blob                -- Convert to MANAGED_POINTER
create vec2.make_from_blob (blob)  -- Restore from BLOB
```

**Features:**
- `SIMPLE_SQL_VECTOR` - Vector representation with math operations
- `SIMPLE_SQL_VECTOR_STORE` - Persistent storage with CRUD and search
- `SIMPLE_SQL_SIMILARITY` - Distance and similarity metrics
- Cosine similarity, Euclidean distance, Manhattan distance
- K-nearest neighbor search
- Threshold-based similarity filtering
- BLOB serialization (IEEE 754 double-precision)
- Metadata storage (JSON) for each vector
- Use cases: RAG, semantic search, recommendation systems, ML feature storage

## BLOB Handling

```eiffel
-- Create table with BLOB column
db.execute ("CREATE TABLE documents (name TEXT, content BLOB)")

-- Insert BLOB using prepared statement (by index)
stmt := db.prepare ("INSERT INTO documents (name, content) VALUES (?, ?)")
stmt.bind_text (1, "image.png")
stmt.bind_blob (2, my_blob_data)  -- MANAGED_POINTER
stmt.execute

-- Insert BLOB using named parameters
stmt := db.prepare ("INSERT INTO documents (name, content) VALUES (:name, :data)")
stmt.bind_text_by_name (":name", "photo.jpg")
stmt.bind_blob_by_name (":data", my_blob_data)
stmt.execute

-- Retrieve BLOB from query
result := db.query ("SELECT content FROM documents WHERE name = 'image.png'")
if attached result.first.blob_value ("content") as blob then
    print ("BLOB size: " + blob.count.out + " bytes")
    -- Access binary data: blob.read_natural_8 (index)
end

-- Read binary file into BLOB
if attached db.read_blob_from_file ("photo.jpg") as file_data then
    stmt := db.prepare ("INSERT INTO documents (name, content) VALUES (?, ?)")
    stmt.bind_text (1, "photo.jpg")
    stmt.bind_blob (2, file_data)
    stmt.execute
end

-- Write BLOB to file
result := db.query ("SELECT content FROM documents WHERE name = 'photo.jpg'")
if attached result.first.blob_value ("content") as blob then
    db.write_blob_to_file (blob, "photo_copy.jpg")
end

-- Complete file storage roundtrip
-- File -> Database -> File
if attached db.read_blob_from_file ("document.pdf") as pdf_data then
    db.execute ("CREATE TABLE files (filename TEXT, data BLOB)")
    stmt := db.prepare ("INSERT INTO files VALUES (?, ?)")
    stmt.bind_text (1, "document.pdf")
    stmt.bind_blob (2, pdf_data)
    stmt.execute

    -- Later: retrieve and save
    result := db.query ("SELECT data FROM files WHERE filename = 'document.pdf'")
    if attached result.first.blob_value ("data") as saved_pdf then
        db.write_blob_to_file (saved_pdf, "document_restored.pdf")
    end
end

-- Handle NULL BLOBs
result := db.query ("SELECT content FROM documents WHERE name = 'empty'")
if result.first.is_null ("content") then
    print ("BLOB is NULL")
else
    blob := result.first.blob_value ("content")
end
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
    ├── query()                -- Query with results (eager)
    ├── query_cursor()         -- Query with lazy cursor (NEW)
    ├── query_stream()         -- Query with callback (NEW)
    ├── create_stream()        -- Create stream object (NEW)
    ├── prepare()              -- Create prepared statement
    ├── select_builder()       -- Create SELECT builder
    ├── insert_builder()       -- Create INSERT builder
    ├── update_builder()       -- Create UPDATE builder
    ├── delete_builder()       -- Create DELETE builder
    ├── schema()               -- Schema introspection
    ├── read_blob_from_file()  -- Load binary file (NEW)
    ├── write_blob_to_file()   -- Save BLOB to file (NEW)
    ├── begin_transaction()
    ├── commit()
    ├── rollback()
    ├── has_error              -- Error status
    ├── last_structured_error  -- Full error details
    └── error_codes            -- Error code constants

SIMPLE_SQL_RESULT             -- Query results (eager loading)
    ├── rows                   -- Iterable collection
    ├── count                  -- Row count
    └── first/last             -- Direct access

SIMPLE_SQL_CURSOR             -- Lazy cursor iteration (NEW)
    ├── start() / forth()      -- Cursor movement
    ├── after                  -- End check
    ├── item                   -- Current row
    ├── rows_fetched           -- Count processed
    ├── close()                -- Release resources
    └── new_cursor             -- For across loops

SIMPLE_SQL_CURSOR_ITERATOR    -- Iterator for across (NEW)
    ├── item                   -- Current row
    ├── after                  -- End check
    ├── forth()                -- Next row
    └── string_value() etc.    -- Direct column access

SIMPLE_SQL_RESULT_STREAM      -- Callback streaming (NEW)
    ├── for_each()             -- Process with early stop
    ├── for_each_do()          -- Process all
    ├── collect_first()        -- Get first N rows
    ├── count_rows()           -- Count total
    ├── first_row()            -- Get first only
    ├── exists()               -- Any rows?
    ├── rows_processed         -- Count processed
    └── was_stopped_early      -- Early termination flag

SIMPLE_SQL_ROW                -- Individual row
    ├── string_value()         -- Type-safe access
    ├── integer_value()
    ├── real_value()
    ├── blob_value()           -- BLOB/binary data (NEW)
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
    ├── bind_blob()            -- Bind BLOB data (NEW)
    ├── bind_null()
    ├── bind_*_by_name()       -- Bind by name (incl. blob) (NEW)
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
    ├── copy_file_to_memory()
    ├── online_backup()        -- Factory: SIMPLE_SQL_ONLINE_BACKUP
    ├── exporter()             -- Factory: SIMPLE_SQL_EXPORT
    └── importer()             -- Factory: SIMPLE_SQL_IMPORT

SIMPLE_SQL_ONLINE_BACKUP      -- SQLite Online Backup API (NEW)
    ├── execute()              -- Complete backup
    ├── execute_incremental()  -- Pages at a time
    ├── set_progress_callback()-- Progress notifications
    ├── progress_percentage()  -- Current progress
    └── close()                -- Release resources

SIMPLE_SQL_EXPORT             -- Export to formats (NEW)
    ├── table_to_csv()         -- Export table to CSV file
    ├── table_csv_string()     -- Export table to CSV string
    ├── table_to_json()        -- Export table to JSON file
    ├── table_json_string()    -- Export table to JSON string
    ├── table_to_sql()         -- Export table to SQL file
    ├── table_sql_string()     -- Export table to SQL string
    └── database_sql_string()  -- Export entire database

SIMPLE_SQL_IMPORT             -- Import from formats (NEW)
    ├── csv_to_table()         -- Import CSV file
    ├── csv_string_to_table()  -- Import CSV string
    ├── json_to_table()        -- Import JSON file
    ├── json_string_to_table() -- Import JSON string
    ├── sql_file()             -- Execute SQL dump file
    └── sql_string()           -- Execute SQL statements

SIMPLE_SQL_FTS5               -- Full-text search (NEW)
    ├── is_fts5_available()    -- Runtime detection
    ├── create_table()         -- FTS5 virtual table
    ├── insert()               -- Add searchable text
    ├── search()               -- Simple MATCH query
    └── query_builder()        -- Fluent FTS5 query

SIMPLE_SQL_FTS5_QUERY         -- FTS5 query builder
    ├── match_all()            -- Boolean AND
    ├── match_any()            -- Boolean OR
    ├── not_matching()         -- Negation
    ├── with_rank()            -- Include BM25 score
    ├── order_by_rank()        -- Sort by relevance
    └── execute()              -- Run search

SIMPLE_SQL_REPOSITORY [G]     -- Generic repository pattern
    ├── find_all()             -- Get all entities
    ├── find_by_id()           -- Find by primary key
    ├── find_where()           -- Conditional query
    ├── find_first_where()     -- First matching entity
    ├── find_all_ordered()     -- Sorted results
    ├── find_all_limited()     -- Pagination support
    ├── count() / count_where()-- Row counting
    ├── exists()               -- ID existence check
    ├── insert()               -- Create new entity
    ├── update()               -- Modify existing
    ├── save()                 -- Insert or update
    ├── delete()               -- Remove by ID
    ├── delete_where()         -- Bulk delete
    └── delete_all()           -- Clear table

SIMPLE_SQL_VECTOR             -- Vector embeddings (NEW)
    ├── make_from_array()      -- Create from REAL_64 array
    ├── make_from_blob()       -- Create from BLOB data
    ├── to_blob()              -- Serialize to BLOB
    ├── magnitude()            -- Euclidean norm
    ├── normalized()           -- Unit vector
    ├── dot_product()          -- Inner product
    ├── add() / subtract()     -- Vector math
    └── scale()                -- Scalar multiplication

SIMPLE_SQL_VECTOR_STORE       -- Vector storage and search (NEW)
    ├── insert()               -- Store vector with metadata
    ├── find_by_id()           -- Retrieve by ID
    ├── find_nearest()         -- K-NN by cosine similarity
    ├── find_nearest_euclidean()-- K-NN by Euclidean distance
    ├── find_within_threshold()-- Similarity threshold filter
    ├── update() / delete()    -- CRUD operations
    └── count() / exists()     -- Queries

SIMPLE_SQL_SIMILARITY         -- Distance/similarity metrics
    ├── cosine_similarity()    -- Angle-based (-1 to 1)
    ├── euclidean_distance()   -- L2 distance
    ├── manhattan_distance()   -- L1 distance
    ├── angular_distance()     -- 1 - cosine
    ├── is_similar()           -- Threshold check
    └── find_most_similar()    -- Best match in array

SIMPLE_SQL_EAGER_LOADER       -- N+1 query prevention (NEW)
    ├── from_table()           -- Set main table
    ├── include()              -- Add direct FK relationship
    ├── include_many_to_many() -- Add M:M via junction table
    ├── where() / limit()      -- Filter main query
    └── execute()              -- Returns SIMPLE_SQL_EAGER_RESULT

SIMPLE_SQL_EAGER_RESULT       -- Eager loading results (NEW)
    ├── main_rows              -- Main query results
    ├── related()              -- All related rows for table
    ├── related_for()          -- Related rows for specific ID
    └── related_count()        -- Count related items

SIMPLE_SQL_PAGINATOR          -- Cursor-based pagination (NEW)
    ├── order_by()             -- Set ordering columns
    ├── page_size()            -- Items per page
    ├── where() / active_only()-- Filtering
    ├── first_page()           -- Get first page
    └── after()                -- Get page after cursor

SIMPLE_SQL_PAGE               -- Pagination result (NEW)
    ├── items                  -- Rows for this page
    ├── next_cursor            -- Cursor for next page
    ├── has_more               -- More pages available?
    └── is_last_page           -- Final page?

SIMPLE_SQL_QUERY_MONITOR      -- N+1 detection (NEW)
    ├── record_query()         -- Track query execution
    ├── warnings               -- N+1 warnings detected
    ├── report()               -- Summary report
    ├── set_threshold()        -- Configure sensitivity
    └── reset()                -- Clear tracking data

AGENT_PART_COMPARATOR [G]     -- Agent-based comparator wrapper
    ├── make()                 -- Create with comparison agent
    └── less_than()            -- PART_COMPARATOR interface
```

## Testing

Comprehensive test suite using EiffelStudio AutoTest framework:

**Core Library Tests:**
- `TEST_SIMPLE_SQL` - Core functionality (19 tests) - includes convenience method tests
- `TEST_SIMPLE_SQL_BACKUP` - Backup operations (5 tests)
- `TEST_SIMPLE_SQL_BATCH` - Batch operations (12 tests) ✅ +1 edge case
- `TEST_SIMPLE_SQL_BLOB` - BLOB handling (7 tests)
- `TEST_SIMPLE_SQL_ERROR` - Error handling (23 tests) ✅ +3 edge cases
- `TEST_SIMPLE_SQL_FTS5` - Full-text search (36 tests) ✅ +5 edge cases
- `TEST_SIMPLE_SQL_JSON` - JSON integration (6 tests)
- `TEST_SIMPLE_SQL_JSON_ADVANCED` - JSON1 extension (27 tests) ✅ +6 edge cases
- `TEST_SIMPLE_SQL_AUDIT` - Change tracking (16 tests)
- `TEST_SIMPLE_SQL_MIGRATION` - Schema migrations (14 tests) ✅ +3 edge cases
- `TEST_SIMPLE_SQL_PRAGMA_CONFIG` - PRAGMA settings (17 tests)
- `TEST_SIMPLE_SQL_PREPARED_STATEMENT` - Prepared statements (12 tests) ✅ +2 edge cases
- `TEST_SIMPLE_SQL_QUERY_BUILDERS` - Query builders (36 tests) ✅ +6 edge cases
- `TEST_SIMPLE_SQL_REPOSITORY` - Repository pattern (23 tests)
- `TEST_SIMPLE_SQL_SCHEMA` - Schema introspection (15 tests) ✅ +4 edge cases
- `TEST_SIMPLE_SQL_STREAMING` - Result streaming (23 tests) ✅ +4 edge cases
- `TEST_SIMPLE_SQL_VECTOR` - Vector embeddings (30 tests) ✅ +8 edge cases
- `TEST_SIMPLE_SQL_ADVANCED_BACKUP` - Online backup, export/import (24 tests) ✅ +8 edge cases
- `TEST_BLOB_DEBUG` - Debug utilities (1 test)

**Mock Application Tests:**
- `TEST_TODO_APP` - TODO application (36 tests)
- `TEST_CPM_APP` - CPM scheduler basic tests (20 tests)
- `TEST_CPM_APP_STRESS` - CPM stress tests with 51-activity construction project (7 tests)
- `TEST_HABIT_TRACKER` - Habit tracking with streaks, analytics (25 tests)
- `TEST_DMS_APP` - Document management system (40 tests)
- `TEST_DMS_STRESS` - DMS stress tests with N+1 detection, pagination, audit (24 tests)
- `TEST_WMS_APP` - Warehouse management basic tests (17 tests)
- `TEST_WMS_STRESS` - WMS stress tests with optimistic locking, bulk operations (8 tests)

**Total: 485+ tests (100% passing)**

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

### ✅ Phase 3: Performance Optimization (COMPLETE)

**Query Result Streaming** ✅
- Lazy cursor iteration (`SIMPLE_SQL_CURSOR`)
- Callback-based streaming (`SIMPLE_SQL_RESULT_STREAM`)
- Memory-efficient processing of large result sets
- Early termination support
- Full `across` loop integration
- Prepared statement and query builder integration

### ✅ Phase 4: Advanced Features (COMPLETE)

**Full-Text Search Integration** ✅
- FTS5 module integration
- Boolean queries (AND, OR, NOT)
- BM25 relevance ranking
- Special character handling (apostrophes)
- Query builder with fluent API

**BLOB Handling** ✅
- BLOB insert/retrieve with prepared statements
- Named parameter binding for BLOBs
- Hex encoding for SQL compatibility
- File → Database operations (`read_blob_from_file`)
- Database → File operations (`write_blob_to_file`)
- NULL BLOB handling
- Large BLOB support (tested with 1MB+)

**Advanced JSON Support** ✅
- JSON path queries (leveraging SQLite json_extract)
- JSON aggregation functions
- JSON modification (set, insert, replace, remove)
- Array and object creation from Eiffel values

**Audit/Change Tracking** ✅
- Auto-generate INSERT/UPDATE/DELETE triggers
- Change log table with JSON storage
- Before/after snapshots
- Timestamp tracking and field-level change detection

**Repository Pattern** ✅
- Generic `SIMPLE_SQL_REPOSITORY [G]` deferred class
- Complete CRUD operations
- Find by ID, find where, find first where
- Pagination and ordering support
- Count and exists queries
- Bulk update and delete operations
- Save (insert-or-update) semantics

### ✅ Phase 5: Specialized Features (COMPLETE)

**Vector Embeddings** ✅
- `SIMPLE_SQL_VECTOR` - Vector representation with math operations
- `SIMPLE_SQL_VECTOR_STORE` - Persistent storage with CRUD
- `SIMPLE_SQL_SIMILARITY` - Distance and similarity metrics
- Cosine similarity, Euclidean distance, Manhattan distance
- K-nearest neighbor search
- Threshold-based similarity filtering
- BLOB serialization (IEEE 754 double-precision)
- Metadata storage (JSON) for each vector

**Advanced Backup** ✅
- `SIMPLE_SQL_ONLINE_BACKUP` - SQLite Online Backup API with progress callbacks
- Incremental backup with configurable pages per step
- `SIMPLE_SQL_EXPORT` - Export to CSV, JSON, SQL dump formats
- `SIMPLE_SQL_IMPORT` - Import from CSV, JSON, SQL formats
- Round-trip data integrity (export then import)

### Phase 6: Concurrency & Atomic Operations (WMS-Driven)

Friction points identified by the WMS mock application:

**Optimistic Locking** (F1)
- `update_versioned(table, id, version, changes)` - Update with version check
- Automatic conflict detection (returns success/conflict)
- Built-in retry support for transient conflicts

**Atomic Operations** (F2)
- `db.atomic(agent)` - Execute agent in transaction with automatic retry
- Rollback on any failure, commit on success
- Configurable retry count for optimistic lock conflicts

**Upsert Pattern** (F4)
- `db.upsert(table, data, conflict_columns)` - Insert or update in single operation
- `db.upsert_batch(table, rows, conflict_columns)` - Bulk upsert
- Leverages SQLite's `INSERT ... ON CONFLICT` syntax

**Conditional Updates** (F3)
- `db.decrement_if(table, column, amount, condition)` - Decrement only if condition met
- `db.increment_if(table, column, amount, condition)` - Increment only if condition met
- Atomic check-and-modify in single statement

### Phase 7: Enterprise Features (Future)

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

- EiffelStudio 25.02+ or Gobo Eiffel Compiler (gobo-25.09+)
- **eiffel_sqlite_2025 v1.0.0+** - Modern SQLite 3.51.1 wrapper with FTS5, JSON1, and advanced features
- SIMPLE_JSON library (for JSON integration)

## License

MIT License - See LICENSE file for details

## Documentation

SIMPLE_SQL includes comprehensive HTML documentation with EiffelStudio EIS integration:

```
docs/
├── index.html              -- Main entry point
├── getting-started.html    -- Quick start guide
├── css/style.css           -- Professional styling
├── api/                    -- API reference
│   ├── database.html       -- SIMPLE_SQL_DATABASE
│   ├── select-builder.html -- Query builder with soft delete scopes
│   ├── eager-loader.html   -- N+1 prevention
│   ├── paginator.html      -- Cursor-based pagination
│   └── query-monitor.html  -- N+1 detection
├── tutorials/              -- How-to guides
│   ├── soft-deletes.html   -- Soft delete patterns
│   └── eager-loading.html  -- Preventing N+1 queries
└── mock-apps/              -- Mock application docs
    ├── todo.html           -- Basic CRUD patterns
    ├── cpm.html            -- Parameterized queries
    ├── habit-tracker.html  -- Time-series data
    ├── dms.html            -- Enterprise patterns
    └── wms.html            -- Concurrency patterns
```

### EIS Integration

Press **F1** in EiffelStudio on any SIMPLE_SQL class to open its documentation. Key classes have EIS annotations:

```eiffel
note
    EIS: "name=API Reference", "src=../docs/api/database.html", "protocol=URI", "tag=documentation"
```

HTML documentation includes links back to EiffelStudio:

```html
<a class="eis-link" href="eiffel:?class=SIMPLE_SQL_DATABASE&feature=query">View Source</a>
```

## Contributing

Contributions welcome! Please ensure:
- All new code includes comprehensive contracts
- Test coverage for all features
- Following established naming conventions
- Documentation for public APIs

## Status

**Current Version:** 1.2
**Stability:** Production - Core API stable
**Production Ready:** Phases 1-5 complete plus DMS-driven and WMS-driven improvements. All features production-ready: core CRUD, prepared statements, PRAGMA configuration, batch operations, fluent query builder, schema introspection, migrations, streaming, FTS5 full-text search, BLOB handling, JSON1 extension, audit tracking, repository pattern, vector embeddings, online backup, export/import, **eager loading**, **soft delete scopes**, **pagination builder**, and **N+1 detection**.
**Test Coverage:** 485+ tests (100% passing) - includes edge case tests from code review + 5 comprehensive mock application test suites
**SQLite Version:** 3.51.1 (via eiffel_sqlite_2025 v1.0.0)
**Mock Apps:** 5 (TODO, CPM, Habit Tracker, DMS, WMS) - demonstrating real-world usage patterns

---

**Built with Eiffel's Design by Contract principles for maximum reliability.**

**Refined through Mock-Driven Development for maximum usability.**
