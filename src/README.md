# SIMPLE_SQL

**High-level SQLite API for Eiffel**

A production-quality, easy-to-use wrapper around the Eiffel SQLite3 library, providing a clean, intuitive interface for database operations with comprehensive error handling and Design by Contract principles.

## Features

### ✅ Implemented (v0.1)

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
SIMPLE_SQL_DATABASE       -- Main database interface
    ├── execute()          -- Command execution
    ├── query()            -- Query with results
    ├── begin_transaction()
    ├── commit()
    └── rollback()

SIMPLE_SQL_RESULT         -- Query results
    ├── rows               -- Iterable collection
    ├── count              -- Row count
    └── first/last         -- Direct access

SIMPLE_SQL_ROW            -- Individual row
    ├── string_value()     -- Type-safe access
    ├── integer_value()
    ├── real_value()
    ├── is_null()
    └── item([index])      -- Generic access

SIMPLE_SQL_BACKUP         -- Backup utilities
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

### Phase 1: Safety & Performance (High Priority)

**Prepared Statements & SQL Injection Prevention**
- Parameterized queries: `query_with_params("SELECT * FROM users WHERE id = ?", [id])`
- Automatic escaping for dynamic SQL
- Type-safe parameter binding

**Connection Pooling**
- Multi-threaded database access
- Connection lifecycle management
- Pool size configuration
- Connection health monitoring

**Performance Optimization**
- Query result streaming for large datasets
- Lazy loading of result rows
- Cursor-based iteration
- Batch insert optimization
- Index suggestion analysis

### Phase 2: Developer Experience (Medium Priority)

**Schema Migration Framework**
- Version-controlled schema changes
- Up/down migration support
- Automatic rollback on failure
- Schema diffing tools

**Query Builder API**
```eiffel
query_builder.select(["name", "age"])
    .from("users")
    .where("age > ?", [25])
    .order_by("name")
    .limit(10)
    .execute(db)
```

**ORM-Like Features**
- Object-to-table mapping
- Automatic CRUD generation
- Relationship handling (1:1, 1:N, N:M)
- Lazy loading of related objects

**Enhanced Error Handling**
- Detailed error context (line numbers, query text)
- Error recovery strategies
- Constraint violation details
- Deadlock detection and retry

### Phase 3: Advanced Features (Specialized)

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

**Current Version:** 0.1-alpha  
**Stability:** Experimental - API may change  
**Production Ready:** Core features stable, advanced features in development

---

**Built with Eiffel's Design by Contract principles for maximum reliability.**
