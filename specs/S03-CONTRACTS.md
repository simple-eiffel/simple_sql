# S03-CONTRACTS: simple_sql

**BACKWASH** | Date: 2026-01-23

## Key Preconditions

### SIMPLE_SQL_REPOSITORY

```eiffel
make (a_database: SIMPLE_SQL_DATABASE)
    require
        database_open: a_database.is_open

find_by_id (a_id: INTEGER_64): detachable G
    require
        valid_id: a_id > 0

find_all_limited (a_limit: INTEGER; a_offset: INTEGER): ARRAYED_LIST [G]
    require
        positive_limit: a_limit > 0
        non_negative_offset: a_offset >= 0
```

### SIMPLE_SQL_PREPARED_STATEMENT

```eiffel
make (a_sql: READABLE_STRING_8; a_database: SQLITE_DATABASE)
    require
        sql_not_empty: not a_sql.is_empty
        database_attached: a_database /= Void
        database_readable: a_database.is_readable

bind_integer (a_index: INTEGER; a_value: INTEGER_64)
    require
        valid_index: a_index >= 1
```

### SIMPLE_SQL_QUERY_BUILDER

```eiffel
set_database (a_database: SIMPLE_SQL_DATABASE)
    require
        database_open: a_database.is_open
```

## Key Postconditions

### SIMPLE_SQL_REPOSITORY

```eiffel
find_all_limited: ARRAYED_LIST [G]
    ensure
        respects_limit: Result.count <= a_limit

count: INTEGER
    ensure
        non_negative: Result >= 0

delete (a_id: INTEGER_64): BOOLEAN
    ensure
        not_exists_if_success: Result implies not exists (a_id)
```

### SIMPLE_SQL_PREPARED_STATEMENT

```eiffel
make
    ensure
        sql_set: sql.same_string (a_sql)
        not_executed: not has_executed

reset
    ensure
        bindings_cleared: bindings.is_empty
        no_error: not has_error
```

## Class Invariants

### SIMPLE_SQL_REPOSITORY

```eiffel
invariant
    database_attached: database /= Void
    database_open: database.is_open
    table_name_valid: not table_name.is_empty
    primary_key_valid: not primary_key_column.is_empty
```

### SIMPLE_SQL_PREPARED_STATEMENT

```eiffel
invariant
    sql_attached: sql /= Void
    database_attached: database /= Void
    bindings_attached: bindings /= Void
```
