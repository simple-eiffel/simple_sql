# 7S-05-SECURITY: simple_sql

**BACKWASH** | Date: 2026-01-23

## Security Considerations

### SQL Injection Prevention
- **Prepared statements**: Parameter binding escapes values automatically
- **Query builders**: Value escaping in value_to_sql and escaped_string
- **Contracts**: Input validation via preconditions

### File Security
- **Database files**: OS-level permissions apply
- **Backup files**: Same permissions as source database
- **No encryption**: SQLite encryption not enabled by default

### Input Validation
- **Non-empty checks**: Table names, column names validated
- **Type checking**: Eiffel type system prevents type confusion
- **Integer IDs**: Primary key constraints enforced

## Known Risks

1. **Path traversal**: Database paths not sanitized - caller responsibility
2. **Concurrent access**: SQLite locking, not designed for heavy concurrent writes
3. **Memory**: Large result sets loaded fully into memory

## Mitigations

- Use prepared statements exclusively for user input
- Validate file paths at application layer
- Use cursor-based iteration for large datasets
