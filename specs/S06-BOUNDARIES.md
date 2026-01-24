# S06-BOUNDARIES: simple_sql

**BACKWASH** | Date: 2026-01-23

## System Boundaries

### External Dependencies

```
+----------------+     +------------------+     +--------+
| Application    | --> | simple_sql       | --> | SQLite |
+----------------+     +------------------+     +--------+
                              |
                              v
                       +--------------+
                       | EiffelStore  |
                       +--------------+
```

### API Boundary

**Public API** (exported to all):
- SIMPLE_SQL_DATABASE: Main entry point
- SIMPLE_SQL_REPOSITORY: Generic persistence
- Query builders: Fluent SQL construction
- Result classes: Query results

**Internal API** (exported to library):
- Implementation helpers
- C external wrappers

### Data Boundaries

| Boundary | Eiffel Type | SQLite Type |
|----------|-------------|-------------|
| Integer | INTEGER_64 | INTEGER |
| Real | REAL_64 | REAL |
| Text | STRING_32 | TEXT |
| Blob | MANAGED_POINTER | BLOB |
| Null | Void | NULL |
| Boolean | BOOLEAN | INTEGER (0/1) |

## Responsibility Boundaries

### simple_sql Responsible For:
- SQL generation and execution
- Parameter binding and escaping
- Result parsing and type conversion
- Connection lifecycle management
- Migration versioning

### Application Responsible For:
- Database file path management
- Entity class definitions
- Repository implementations
- Business logic validation
- Error handling decisions

### SQLite Responsible For:
- Query optimization
- Transaction management
- File I/O
- Locking and concurrency
