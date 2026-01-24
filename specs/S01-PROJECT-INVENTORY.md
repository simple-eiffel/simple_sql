# S01-PROJECT-INVENTORY: simple_sql

**BACKWASH** | Date: 2026-01-23

## Project Structure

```
simple_sql/
├── src/
│   ├── simple_sql_*.e          # Core library classes
│   ├── todo_app/               # Demo: Todo application
│   ├── cpm_app/                # Demo: Critical Path Method
│   ├── dms/                    # Demo: Document Management
│   ├── habit_tracker/          # Demo: Habit tracking
│   └── wms/                    # Demo: Warehouse Management
├── testing/
│   ├── test_simple_sql*.e      # Core tests
│   ├── todo_app/               # Todo tests
│   ├── cpm_app/                # CPM tests
│   ├── dms/                    # DMS tests
│   └── habit_tracker/          # Habit tests
├── simple_sql.ecf              # Library ECF
├── research/                   # Research documents
└── specs/                      # Specification documents
```

## Key Files

| File | Purpose |
|------|---------|
| simple_sql_repository.e | Generic repository pattern |
| simple_sql_query_builder.e | Base query builder |
| simple_sql_select_builder.e | SELECT statement builder |
| simple_sql_prepared_statement.e | Parameterized queries |
| simple_sql_migration.e | Schema migration base |
| simple_sql_migration_runner.e | Migration execution |
| simple_sql_fts5.e | Full-text search |
| simple_sql_json.e | JSON extension support |

## Configuration Files

- **simple_sql.ecf**: Main library configuration
- Uses EiffelStore/SQLite as dependency
- Void safety: Complete
