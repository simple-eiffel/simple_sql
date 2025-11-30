# SIMPLE_SQL

**High-level SQLite API for Eiffel**

A production-quality, easy-to-use wrapper around the Eiffel SQLite3 library, providing a clean, intuitive interface for database operations with comprehensive error handling and Design by Contract principles.

## Features

### ✅ Implemented (v0.4)

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
- Comprehensive test suite with 210 tests (21 new JSON1 tests)

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
    └── copy_file_to_memory()

SIMPLE_SQL_FTS5               -- Full-text search (NEW)
    ├── is_fts5_available()    -- Runtime detection
    ├── create_table()         -- FTS5 virtual table
    ├── insert()               -- Add searchable text
    ├── search()               -- Simple MATCH query
    └── query_builder()        -- Fluent FTS5 query

SIMPLE_SQL_FTS5_QUERY         -- FTS5 query builder (NEW)
    ├── match_all()            -- Boolean AND
    ├── match_any()            -- Boolean OR
    ├── not_matching()         -- Negation
    ├── with_rank()            -- Include BM25 score
    ├── order_by_rank()        -- Sort by relevance
    └── execute()              -- Run search
```

## Testing

Comprehensive test suite using EiffelStudio AutoTest framework:
- `TEST_SIMPLE_SQL` - Core functionality (12 tests)
- `TEST_SIMPLE_SQL_BACKUP` - Backup operations (5 tests)
- `TEST_SIMPLE_SQL_JSON` - JSON integration (5 tests)
- `TEST_SIMPLE_SQL_FTS5` - Full-text search (29 tests) ✅
- `TEST_SIMPLE_SQL_BLOB` - BLOB handling (7 tests) ✅
- `TEST_BLOB_DEBUG` - Debug utilities (1 test) ✅

**Total: 189 tests passing (100% success rate)**

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

### ✅ Phase 4: Advanced Features (PARTIALLY COMPLETE)

**Full-Text Search Integration** ✅
- FTS5 module integration ✅
- Boolean queries (AND, OR, NOT) ✅
- BM25 relevance ranking ✅
- Special character handling (apostrophes) ✅
- Query builder with fluent API ✅
- Highlight/snippet generation (future enhancement)

**BLOB Handling** ✅
- BLOB insert/retrieve with prepared statements ✅
- Named parameter binding for BLOBs ✅
- Hex encoding for SQL compatibility ✅
- File → Database operations (`read_blob_from_file`) ✅
- Database → File operations (`write_blob_to_file`) ✅
- NULL BLOB handling ✅
- Large BLOB support (tested with 1MB+) ✅
- Incremental I/O via native SQLite (future enhancement)

**Advanced JSON Support** (Next)
- JSON path queries (leveraging SQLite json_extract)
- JSON aggregation functions
- Schema validation integration
- Partial updates with JSON Patch/Merge Patch

**Audit/Change Tracking** (Next)
- Auto-generate triggers
- Change log table with JSON diffs
- Before/after snapshots
- Timestamp and user tracking

### Phase 5: Enterprise Features (Future)

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

## Contributing

Contributions welcome! Please ensure:
- All new code includes comprehensive contracts
- Test coverage for all features
- Following established naming conventions
- Documentation for public APIs

## Status

**Current Version:** 0.6
**Stability:** Beta - Core API stable
**Production Ready:** Core features, FTS5 full-text search, and BLOB handling production-ready
**Test Coverage:** 189 tests passing (100% success rate)
**SQLite Version:** 3.51.1 (via eiffel_sqlite_2025 v1.0.0)

---

**Built with Eiffel's Design by Contract principles for maximum reliability.**
