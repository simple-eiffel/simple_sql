# S02-CLASS-CATALOG: simple_sql

**BACKWASH** | Date: 2026-01-23

## Core Classes

| Class | Type | Description |
|-------|------|-------------|
| SIMPLE_SQL_DATABASE | Concrete | Main database connection and operations |
| SIMPLE_SQL_RESULT | Concrete | Query result container |
| SIMPLE_SQL_ROW | Concrete | Single result row |
| SIMPLE_SQL_ERROR | Concrete | Error information |
| SIMPLE_SQL_ERROR_CODE | Concrete | SQLite error codes |

## Query Builder Classes

| Class | Type | Description |
|-------|------|-------------|
| SIMPLE_SQL_QUERY_BUILDER | Deferred | Base query builder |
| SIMPLE_SQL_SELECT_BUILDER | Concrete | SELECT statement builder |
| SIMPLE_SQL_INSERT_BUILDER | Concrete | INSERT statement builder |
| SIMPLE_SQL_UPDATE_BUILDER | Concrete | UPDATE statement builder |
| SIMPLE_SQL_DELETE_BUILDER | Concrete | DELETE statement builder |
| SIMPLE_SQL_RAW_EXPRESSION | Concrete | Raw SQL expressions |

## Statement Classes

| Class | Type | Description |
|-------|------|-------------|
| SIMPLE_SQL_PREPARED_STATEMENT | Concrete | Parameterized queries |
| SIMPLE_SQL_CURSOR | Concrete | Lazy row iteration |
| SIMPLE_SQL_CURSOR_ITERATOR | Concrete | Cursor traversal |
| SIMPLE_SQL_RESULT_STREAM | Concrete | Callback-based results |
| SIMPLE_SQL_BATCH | Concrete | Batch operations |

## Pattern Classes

| Class | Type | Description |
|-------|------|-------------|
| SIMPLE_SQL_REPOSITORY [G] | Deferred | Generic entity repository |
| SIMPLE_SQL_MIGRATION | Deferred | Database migration |
| SIMPLE_SQL_MIGRATION_RUNNER | Concrete | Migration execution |

## Extension Classes

| Class | Type | Description |
|-------|------|-------------|
| SIMPLE_SQL_FTS5 | Concrete | Full-text search |
| SIMPLE_SQL_FTS5_QUERY | Concrete | FTS5 query builder |
| SIMPLE_SQL_JSON | Concrete | JSON functions |
| SIMPLE_SQL_VECTOR | Concrete | Vector operations |

## Utility Classes

| Class | Type | Description |
|-------|------|-------------|
| SIMPLE_SQL_BACKUP | Concrete | Database backup |
| SIMPLE_SQL_ONLINE_BACKUP | Concrete | Hot backup |
| SIMPLE_SQL_EXPORT | Concrete | Data export |
| SIMPLE_SQL_IMPORT | Concrete | Data import |
| SIMPLE_SQL_PAGINATOR | Concrete | Result pagination |
| SIMPLE_SQL_PAGE | Concrete | Single page of results |
| SIMPLE_SQL_PRAGMA_CONFIG | Concrete | SQLite PRAGMA settings |

## Schema Classes

| Class | Type | Description |
|-------|------|-------------|
| SIMPLE_SQL_SCHEMA | Concrete | Schema introspection |
| SIMPLE_SQL_TABLE_INFO | Concrete | Table metadata |
| SIMPLE_SQL_COLUMN_INFO | Concrete | Column metadata |
| SIMPLE_SQL_INDEX_INFO | Concrete | Index metadata |
| SIMPLE_SQL_FOREIGN_KEY_INFO | Concrete | Foreign key metadata |
