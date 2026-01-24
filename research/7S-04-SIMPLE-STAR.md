# 7S-04-SIMPLE-STAR: simple_sql

**BACKWASH** | Date: 2026-01-23

## Ecosystem Integration

### Dependencies (Incoming)
- **EiffelBase**: Core data structures (ARRAYED_LIST, HASH_TABLE)
- **EiffelStore/SQLite**: Low-level SQLITE_DATABASE, SQLITE_STATEMENT

### Dependents (Outgoing)
- **simple_oracle**: Uses simple_sql for oracle database
- **simple_http**: Session storage
- **simple_auth**: User credential storage
- **simple_log**: Log persistence

## Integration Patterns

### Database Creation
```eiffel
db: SIMPLE_SQL_DATABASE
create db.make ("myapp.db")
```

### Query Builder Pattern
```eiffel
result := db.select_builder
    .select_all
    .from_table ("users")
    .where ("active = 1")
    .order_by ("name")
    .execute
```

### Repository Pattern
```eiffel
class USER_REPOSITORY inherit SIMPLE_SQL_REPOSITORY [USER]
```

## Ecosystem Fit

- Core data layer for Simple Eiffel applications
- Foundation library - high stability requirement
- Used by oracle-cli for ecosystem metadata
