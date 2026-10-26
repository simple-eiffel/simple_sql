# Design Scan (diff mode): simple_sql since 14c4f17 (..729b8b6)
Date: 2026-10-26. Read-only; nothing compiled or run. Subjects: src/simple_sql_cursor.e (only src change), testing/lib_tests.e.
Runtime behavior of SQLite below is inferred from reading code, not executed; each item says what to verify.

## HIGH

### H1. Step error leaves the statement open and the cursor stale
- eiffel_sqlite_2025/sqlite_statement_iteration_cursor.e:206-258: `forth` raises (`l_exception.raise` / `sqlite_raise_on_failure`) when sqlite3_step fails. Errors are NOT swallowed, but:
- src/simple_sql_cursor.e:168-171 `forth` has no rescue; the raise skips `take_current_step` (171), so `finish` (267-278) never runs. `has_valid_row` stays True (stale row), `after` stays False, statement stays prepared mid-step.
- Scenario: file DB, a writer holds the lock, step returns SQLITE_BUSY. Caller wraps the loop in rescue/retry: `after` is False, so it re-steps the errored statement and gets the same error forever; the open read statement also pins the connection (blocks close, WAL checkpoint).
- Same at `start` (143-152): `statement := l_statement` is set (146), then `execute_new` raises inside its make->start->forth; `steps` stays Void, `is_started` is already True (142), statement leaks until GC.
- Fix: `rescue` in `start`/`forth` that calls `finish`, sets `has_valid_row := False`, re-raises.

### H2. Abandoned cursor holds an open statement until GC; no dispose
- Release happens only on exhaustion (cursor.e:246-247) or `close` (206-207). An `across` loop left early (find-first pattern, exception) never reaches either. SIMPLE_SQL_CURSOR has no `dispose`.
- Scenario: `across db.query_cursor (q) as ic loop if found then Result := ic.item; leave end end` keeps the statement live. SQLITE_STATEMENT.dispose (sqlite_statement.e:89-135) finalizes it only when GC reclaims it, and skips it in final collect. Until then: file-DB read lock held; `db.close` falls to sqlite3_close_v2 (sqlite_database.e:702-712) leaving a zombie connection. Under SCOOP the finalizing thread is whichever collects; the E_MISUSE tolerance (sqlite_statement.e:118-121) prevents a crash but timing is nondeterministic.
- Fix: document "exhaust or close" on `query_cursor`/`new_cursor`; consider a `first_row`/`do_all` helper that guarantees `close`. Verify with a test: start cursor, drop it, `db.close`, reopen file.

## MEDIUM

### M1. `close` mid-iteration does not make `after` true
- cursor.e:206-208 sets `is_closed` and calls `finish` but leaves `has_valid_row` True. `after` (108) stays False, `item` still returns the stale row (its `not_after` precondition passes), and an `until after` loop runs one more body. Fix: `has_valid_row := False` in `close`.

### M2. Query that fails to compile is silently an empty result
- cursor.e:145-150: not compiled -> statement cleaned up, cursor acts as zero rows. `last_exception` (sqlite_statement.e:678-681) is dropped, and `query_cursor` (database.e:861-870) already ran `clear_error`, so `db.has_error` is False. A typo in SQL looks like "no matches"; eager `query` reports it. Fix: expose the error on the cursor (`last_error`/`is_valid`) or raise.

### M3. `new_cursor` is not fresh
- cursor.e:79-88 says "Fresh iterator", but SIMPLE_SQL_CURSOR_ITERATOR.make (iterator.e:37-40) only starts if `not is_started`. A second `across` over the same cursor is silently empty (the statement is gone and nothing re-runs). Fix the comment or make `new_cursor` restart.

### M4. Dead weight and a tautological contract
- `pending_rows` (cursor.e:219, created 50, wiped 208), `pending_rows_model` (176-192), `is_exhausted` (235; set at 53/270, never read - grep over src/testing finds no reader) are dead. Invariant `pending_rows_attached` (283) and `close` postcondition `buffer_empty: pending_rows_model.is_empty` (211) assert on a structure that is always empty. Replace the postcondition with `not is_open` plus `after` (see M1). `pending_rows_model` is exported API: check clients (simple_bible) before removing.

### M5. The laziness test does not prove laziness
- testing/lib_tests.e:771 asserts `pending_rows_model.count = 0`, and that model is built from a list nothing fills any more: it passes by construction, and would pass on any implementation that leaves that list alone. Order and count (772-780) are real but an eager implementation also satisfies them. A true proof: `SELECT CASE WHEN x = 3 THEN abs(-9223372036854775808) ELSE x END AS x FROM n ORDER BY x` (SQLite integer overflow error at row 3 only). Lazy: `start` and two `forth` succeed, the error arrives on the third. Eager: fails at `start`. It also exercises H1. Alternatively assert `rows_fetched = 1` right after `start` (cursor.e:243 already counts; the test never checks it there).

## LOW

### L1. Timing test: small flake risk
- lib_tests.e: `cursor_ns <= 3 * eager_ns + 50 ms` over 40,000 rows, contracts off. Old behavior was 40x, so it discriminates. Risk: eager runs first and its 40k retained rows raise GC pressure during the cursor run; one GC cycle on a loaded box can exceed the 50 ms slack. Mitigate: run cursor first, or best of 3, or collect before each timing. `eager_ns`/`cursor_ns`/`cursor_rows` are shared class attributes (fine serially).

### L2. Database close or writes mid-iteration
- cursor.e:216 keeps the raw SQLITE_DATABASE; `is_readable` is checked only in `make` (40). SIMPLE_SQL_DATABASE.close (database.e:445-464) knows nothing of cursors; with a live statement the connection becomes a close_v2 zombie and a later `forth` steps on it (verify whether sqlite3_step still returns rows there). Writing the scanned table on the same connection mid-walk gives SQLite-defined but surprising visibility (rows skipped or repeated). Document, no machinery.

### L3. Sibling creators
- SIMPLE_SQL_SELECT_BUILDER.execute_cursor (select_builder.e:769) returns `detachable`; PREPARED_STATEMENT (prepared_statement.e:305) and FTS5_QUERY (fts5_query.e:363) return attached. PREPARED_STATEMENT.execute_cursor (315-317) interpolates values into SQL text (`sql_with_bound_values`) because `execute_new` requires `not has_arguments` (sqlite_statement.e:167), so real binding (`execute_new_with_arguments`) is not used. All three inherit H1/H2/M2 with no code change of their own.

## DUPLICATION (A5)
Three equivalent copies of "SQLITE_RESULT_ROW -> SIMPLE_SQL_ROW":
- SIMPLE_SQL_CURSOR.new_row (cursor.e:251-265)
- SIMPLE_SQL_RESULT.collect_row (result.e:166-189; adds `rows.extend`, `Result := False`)
- SIMPLE_SQL_RESULT_STREAM.convert_row (result_stream.e:270-289; hoists `l_col_name`)
No drift today. SIMPLE_SQL_ROW already exports `add_column` to exactly these three (row.e:509), so the owner is obvious: a creation procedure `make_from_sqlite (a_row: SQLITE_RESULT_ROW)` on SIMPLE_SQL_ROW; each caller becomes one line, and `add_column` export can narrow. Effort: 1 feature, 3 call sites (refactor branch; /eiffel.abstract is overkill). Otherwise any column-name policy change (case, duplicates, to_string_8 on non-ASCII names) will drift across the copies.

## Recommended order
H1 with the M5 test, M1, M2, duplication extraction, M4 cleanup (client check first), H2 docs, rest.
