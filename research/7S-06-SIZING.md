# 7S-06-SIZING: simple_sql

**BACKWASH** | Date: 2026-01-23

## Codebase Metrics

- **Source Files**: 70+ .e files
- **Core Classes**: ~40 classes
- **Test Classes**: 30+ test files
- **LOC Estimate**: ~8,000 lines

## Class Categories

| Category | Count | Classes |
|----------|-------|---------|
| Core Database | 5 | SIMPLE_SQL_DATABASE, RESULT, ROW, ERROR, BATCH |
| Query Builders | 5 | SELECT, INSERT, UPDATE, DELETE, QUERY_BUILDER |
| Prepared Statements | 3 | PREPARED_STATEMENT, CURSOR, RESULT_STREAM |
| Repository | 1 | SIMPLE_SQL_REPOSITORY |
| Migration | 2 | MIGRATION, MIGRATION_RUNNER |
| Utilities | 10+ | PAGINATOR, BACKUP, EXPORT, IMPORT, FTS5, JSON |
| Demo Apps | 15+ | TODO, CPM, DMS, HABIT_TRACKER, WMS |

## Complexity Assessment

- **High Complexity**: Query builders (SQL generation), Parser
- **Medium Complexity**: Repository (generic mapping), Migration
- **Low Complexity**: Result handling, Error codes

## Resource Requirements

- Memory: Scales with result set size
- Disk: SQLite database file size
- CPU: Query execution time (SQLite)
