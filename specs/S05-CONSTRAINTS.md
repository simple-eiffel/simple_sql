# S05-CONSTRAINTS: simple_sql

**BACKWASH** | Date: 2026-01-23

## Technical Constraints

### SQLite Constraints
- **Single Writer**: Only one writer at a time (SQLite limitation)
- **File-Based**: Database must be accessible as file path
- **Size Limit**: 281 TB theoretical max (practical: available disk)
- **Row Size**: 1 GB max per row (BLOB limit)

### Eiffel Constraints
- **Void Safety**: Must compile with void safety enabled
- **Generic Types**: Repository G must be ANY descendant
- **String Types**: Mix of STRING_8 and STRING_32 for compatibility

### Platform Constraints
- **Windows Primary**: Tested primarily on Windows
- **EiffelStudio**: Requires EiffelStudio 25.02+
- **SQLite Version**: Uses bundled SQLite (version varies with ES)

## Design Constraints

### Performance
- **Eager Loading**: Results loaded into memory by default
- **Cursor Alternative**: Use cursors for large result sets
- **Index Usage**: Caller responsible for proper indexing

### Concurrency
- **Not Thread-Safe**: Single-threaded access assumed
- **SCOOP Ready**: Prepared for SCOOP but not required

### Memory
- **Result Sets**: Full result sets in memory
- **Large Results**: May cause memory pressure
- **Mitigation**: Use LIMIT/OFFSET or cursors

## Compatibility Constraints

### SQL Dialect
- SQLite-specific SQL
- No RETURNING clause (separate query for ID)
- JSON1 and FTS5 extensions assumed available
