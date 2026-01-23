# SQLite / Database Gotchas in Eiffel

This file tracks SQLite and database-specific issues when working with Eiffel.

Applies to: `eiffel_sqlite_2025`, `simple_sql`, and similar SQLite wrapper projects.

---

## SQLite Wrapper Issues

### SQLITE_DATABASE Missing Features
- **Docs say**: (assumed) `last_row_id` exists on SQLITE_DATABASE
- **Reality**: `last_row_id` only exists on SQLITE_INSERT_STATEMENT, not SQLITE_DATABASE
- **Verified**: 2025-11-29, EiffelStudio 24.x
- **Example**:
```eiffel
-- WRONG: Feature doesn't exist
Result := internal_db.last_row_id

-- CORRECT: Use SQL query
create l_result.make ("SELECT last_insert_rowid();", internal_db)
if not l_result.rows.is_empty and then attached l_result.rows.first as l_row then
    if attached {INTEGER_64} l_row.item (1) as l_id then
        Result := l_id
    end
end
```

### SIMPLE_SQL_ROW Access Methods
- **Docs say**: (assumed) `integer_value_at(index)` for positional access
- **Reality**: Use `item(index)` for positional access, `integer_value(name)` for named access
- **Verified**: 2025-11-29, EiffelStudio 24.x
- **Example**:
```eiffel
-- WRONG: Feature doesn't exist
Result := l_row.integer_value_at (1)

-- CORRECT: Use item() with type cast
if attached {INTEGER_64} l_row.item (1) as l_count then
    Result := l_count.to_integer_32
end

-- OR use named access if column name is known
Result := l_row.integer_value ("count")
```

### SQLite Statements Require Semicolon Terminator
- **Docs say**: (assumed) SQL strings are passed directly to SQLite
- **Reality**: `SQLITE_MODIFY_STATEMENT.make` and `SQLITE_QUERY_STATEMENT.make` have precondition `a_statement_is_complete` which calls `a_db.is_complete_statement(a_sql)`. SQLite requires SQL to end with `;`
- **Verified**: 2025-11-29, EiffelStudio 24.x
- **Example**:
```eiffel
-- WRONG: Precondition violation (a_statement_is_complete)
create l_statement.make ("INSERT INTO test VALUES (1)", database)

-- CORRECT: Add semicolon
l_sql := "INSERT INTO test VALUES (1)"
if not l_sql.ends_with (";") then
    l_sql.append_character (';')
end
create l_statement.make (l_sql, database)
```

### SQLite Type Conversion in Query Results
- **Docs say**: (assumed) Query results can be cast directly to STRING_32
- **Reality**: SQLite query results need `.out` conversion before type-checking or string operations
- **Verified**: 2025-11-30, EiffelStudio 25.02
- **Example**:
```eiffel
-- WRONG: Direct cast fails for SQLite compile options
if attached {STRING_32} ic.item (1) as l_str then
    l_option := l_str.as_upper  -- Never executes!
end

-- CORRECT: Use .out to convert first
if attached ic.item (1) as l_val then
    create l_option.make_from_string (l_val.out)  -- .out converts ANY to string
    l_option.to_upper
end
```

### FTS5 Query Escaping for Apostrophes
- **Docs say**: (SQLite FTS5 docs) Special characters in queries need escaping
- **Reality**: Apostrophes (single quotes) in FTS5 queries need BOTH phrase matching AND SQL escaping
- **Verified**: 2025-11-30, SQLite 3.51.1, EiffelStudio 25.02
- **Example**:
```eiffel
-- WRONG: Apostrophe breaks query
fts5.search ("documents", "O'Brien")  -- Fails: tokenizer splits at '

-- CORRECT: Wrap in double quotes for phrase matching, escape apostrophe for SQL
-- Query becomes: MATCH '"O''Brien"'
-- (double quotes for FTS5 phrase, doubled apostrophe for SQL literal)
escaped := escaped_fts_query ("O'Brien")
-- Result: "O''Brien" with phrase matching
```

### SQLite Statements Must Be Single-Line
- **Docs say**: (assumed) Multi-line SQL strings work normally
- **Reality**: `SQLITE_MODIFY_STATEMENT.make` precondition `a_statement_is_complete` calls `a_db.is_complete_statement(a_sql)` which fails on multi-line SQL
- **Verified**: 2025-12-01, EiffelStudio 25.02
- **Example**:
```eiffel
-- WRONG: Multi-line SQL fails precondition
l_sql := "[
    CREATE TABLE IF NOT EXISTS test (
        id INTEGER PRIMARY KEY,
        name TEXT
    )
]"
database.execute (l_sql)  -- Precondition failure!

-- CORRECT: Single-line SQL
l_sql := "CREATE TABLE IF NOT EXISTS test (id INTEGER PRIMARY KEY, name TEXT)"
database.execute (l_sql)  -- Works
```

---

## C Compilation Issues

### SQLite Runtime Linking (C Library Compilation)
- **Docs say**: (Visual Studio) Use /MD for dynamic runtime linking
- **Reality**: Eiffel projects use -NODEFAULTLIB:libc flag, requiring /MT (static runtime) for SQLite C compilation
- **Verified**: 2025-11-30, MSVC 19.44, EiffelStudio 25.02
- **Symptoms**: `unresolved external symbol __imp_strcspn` linker error when using /MD
- **Example**:
```batch
REM WRONG: Dynamic runtime causes linker errors
cl /c /O2 /MD sqlite3.c

REM CORRECT: Static runtime embeds C runtime functions
cl /c /O2 /MT sqlite3.c
```

### EiffelStudio Clean Rebuild for Compile Flag Changes
- **Docs say**: (assumed) Recompiling C files is sufficient
- **Reality**: When SQLite compile flags change (e.g., adding SQLITE_ENABLE_FTS5), must use "Compile from scratch" to clear EIFGENs cache
- **Verified**: 2025-11-30, EiffelStudio 25.02
- **Symptoms**: Tests fail even after recompiling .obj files because EiffelStudio uses cached object files
- **Solution**: Project > Compile from scratch (deletes EIFGENs folder completely)

### Gobo Eiffel Runtime Type Definitions
- **Docs say**: (assumed) EIF_NATURAL is a standard type
- **Reality**: Gobo Eiffel runtime defines specific types (EIF_NATURAL_8/16/32/64) but NOT the generic EIF_NATURAL
- **Verified**: 2025-11-30, Gobo Eiffel gobo-25.09
- **Example**:
```c
// WRONG: Compile error with Gobo runtime
void my_function(EIF_NATURAL value) { ... }  // Error: EIF_NATURAL undeclared

// CORRECT: Add compatibility definition
#ifndef EIF_NATURAL
#define EIF_NATURAL EIF_NATURAL_32
#endif
void my_function(EIF_NATURAL value) { ... }  // Now works with both runtimes
```

---

## Threading Issues

### SQLite Connections Are Thread-Bound (EiffelWeb Thread Pool)
- **Docs say**: (assumed) SQLite connections work across threads
- **Reality**: SQLite connections opened on Thread A cannot be used from Thread B. EiffelWeb uses a thread pool (`POOLED_THREAD`) for request handling, so connections opened on main thread fail when accessed from worker threads.
- **Verified**: 2025-12-07, EiffelStudio 25.02, EiffelWeb/WSF
- **Symptoms**: Intermittent `PRECONDITION_VIOLATION` on `a_db_is_accessible` in `SQLITE_MODIFY_STATEMENT.make`. The check passes early (same thread) then fails once thread pool handles requests.
- **Diagnosis**: Call stack shows `POOLED_THREAD` - dead giveaway of cross-thread access.
- **Example**:
```eiffel
-- WRONG: Shared connection created on main thread
class MY_MIDDLEWARE
feature
    make (a_db: MY_DATABASE)
        do
            database := a_db  -- Created on main thread!
        end

    process (request, response, next)
        do
            database.insert (...)  -- Called from worker thread - FAILS!
        end
end

-- CORRECT: Per-request connection
class MY_MIDDLEWARE
feature
    make (a_db_path: STRING)
        do
            db_path := a_db_path
        end

    process (request, response, next)
        local
            l_db: SIMPLE_SQL_DATABASE
        do
            create l_db.make (db_path)  -- Fresh connection on THIS thread
            l_db.execute_with_args ("INSERT ...", <<...>>)
            l_db.close
        end
end
```
- **Note**: SQLite file opens are sub-millisecond. Per-request connections is the standard pattern (Django, Rails, etc.).
