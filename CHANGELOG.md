# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.2] - 2026-10-08

### Fixed
- **`todo_app_tests` did not compile** (VMFN): `TASK_DEPENDENCY` defined `out` without redefining
  `ANY.out`. It now inherits `ANY` with `redefine out`.
- **`todo_app_tests` ran nothing:** its root `APPLICATION.make` was empty. It now runs all 36 tests of
  `TEST_TODO_APP` and `TEST_TODO_APP_STRESS` through `EQA_TEST_EVALUATOR` and prints a summary.
- **`TODO_REPOSITORY.mark_completed` / `mark_incomplete` left the item's state unchanged:** they set only
  `is_completed`, while `TODO_ITEM` reads its state from the `status` column. Both now go through
  `set_status` ("completed" / "pending"). The rename damage repaired in 1.3.1 had hidden this: with the
  key misspelled as `"l_status"`, the row reader fell back to `is_completed`.
- Result: `todo_app_tests` 36 passed, 0 failed.

### Known
- The `cpm_app_tests`, `habit_tracker_tests` and `dms_tests` roots (`APPLICATION.make`) are also empty and
  `wms_tests` roots at `ANY.default_create`, so those mock-app tests do not run yet.

## [1.3.1] - 2026-10-08

### Fixed
- **String literals damaged by the 2026-02-06 naming-standards commit (eb10f9d) are restored.** The rename
  script also rewrote text inside string literals: SQL (`SELECT l_name FROM sqlite_master`, `l_type`,
  `l_sort_order`, `l_stock`, `l_path`, `l_snippet(...)`, `l_product_id`, ...), result column keys
  (`string_value ("l_name")`, `"l_origin"`, `"l_from"`, `"l_to"`, `"l_old_values"`, ...), audit action names
  (`"l_user"`, `"l_comment"`, `"l_share"`), messages (`"No l_migration found for version "`,
  `"Restored from l_version "`) and test data (`"l_folder@example.com"`, `"Non-l_critical"`, JSON keys).
  Every literal was taken from that commit's own diff (old text against new text, line by line), not
  inferred: 121 occurrences in 22 files, all reverted to the pre-rename text. The two other rename commits
  (75ffe90, 07cc528) changed no code literal. This damage caused all 40 tests that had been failing in the
  unwired test classes (schema introspection, audit, FTS5 column helpers, advanced backup, JSON).
- Full EQA run of all 419 tests in the `testing` classes: 419 passed, 0 failed (was 379/40).

## [1.3.0] - 2026-10-08

Error integrity (fork 02 verdict, F-9 items a-d and f-i), read-only ATTACH, and the eiffel_sqlite_2025 1.1.0
engine (SQLite 3.53.4). **Behavior changes:** errors are sticky inside a transaction, `atomic` and `commit`
roll back a transaction in which a statement failed, and `execute_with_args` now reports failures. Clients
that relied on partial commits or on silent failures will see different results. Rebuild every client with
`-clean` after updating eiffel_sqlite_2025.

### Fixed
- **`execute_with_args` / `perform_with` failed silently** (F-9 a). It never checked the result; a failed
  INSERT left `has_error` False. It now reports SQLite's error. `SIMPLE_SQL_PREPARED_STATEMENT.execute`
  sets `last_error` for modifications and queries. The "bind variables" note is corrected: values are
  escaped and substituted as SQL literals.
- **Errors inside a transaction were forgotten by the next statement** (F-9 b). Every `execute` began with
  `clear_error`, so a failure in the middle of a transaction vanished. Now the transaction's first error
  is kept (`transaction_error`, `is_transaction_failed`) and `has_error` stays True until the transaction
  ends.
- **`atomic` committed partial work** (F-9 c). It rolled back only on an exception; a failed middle
  statement was committed with the rest. Now it checks the transaction after the agent, rolls back
  **before** any COMMIT, rolls back on a failed COMMIT, and reports the outcome in `has_error` /
  `last_error_message` (also when the agent raised).
- **`commit` / `commit_transaction` cleared the error, then committed** (F-9 d). A failed transaction is
  now rolled back instead of committed, keeping its error; a failed COMMIT is reported.
- **`rollback_transaction` erased the error the caller was about to read** (F-9 f).
- **The migration runner stamped a migration whose middle statement failed** (F-9 g). It checked
  `has_error` once, after `up`, which reflected only the last statement. Now any failed statement, a failed
  version stamp, a failed COMMIT or an exception rolls the migration back, returns False, leaves
  `user_version` unchanged and keeps SQLite's message: `Migration 1 failed: UNIQUE constraint failed: m1.id`
  (it was `Migration 1 failed`).
- **`close` failed after a statement that did not compile** (F-9 h). `execute`, `query` and the prepared
  statement no longer step a statement that failed to compile (its error is reported); with
  eiffel_sqlite_2025 1.1.0 the lock is also released by the library. `close` also rolls back a transaction
  left open by a failed COMMIT before closing.
- **Online backup ended on SQLITE_BUSY / SQLITE_LOCKED** (F-9 i). SQLite documents both as retryable. A step
  is now retried up to `max_busy_retries` times (default 200), `busy_retry_delay_ms` apart (default 25),
  with an optional `busy_retry_callback`; `busy_retries_done` reports the count.
- **SQLite's error message was lost.** Errors took their text from `SQLITE_EXCEPTION.description`, which is
  usually Void, so messages read "Unknown error". They now carry SQLite's text (from `tag`).
- README: the false "SQLite 3.51.1" lines (Dependencies, Status) and the unsupported test-count claims.

### Added
- `attach_read_only (file, schema)`, `detach (schema)`, `is_attached (schema)`, `is_valid_schema_name`,
  `read_only_uri (file)`: ATTACH an existing file **read-only** through a `file:` URI with `mode=ro`, on a
  read-only connection (where `execute ("ATTACH ...")` cannot run) or a read-write one (D4). Relies on
  eiffel_sqlite_2025 1.1.0 opening connections with `SQLITE_OPEN_URI` (D7).
- `is_transaction_failed`, `transaction_error`.
- `SIMPLE_SQL_ONLINE_BACKUP.set_busy_retry`, `set_busy_retry_callback`, `max_busy_retries`,
  `busy_retry_delay_ms`, `busy_retries_done`.
- `TEST_SIMPLE_SQL_INTEGRITY` (23 tests, wired into `TEST_APP`): one or more tests per item above, the
  ADJ-p-atomic probes as tests, read-only attach, the linked version (3.53.4) and the bare
  `PRAGMA foreign_key_check` with a parent table of the same name in an attached file.

### Known, not fixed here
- 40 tests in the `testing` classes that `TEST_APP` does not run were already failing before 1.3.0 and
  still fail. Most come from SQL text altered by the 2026-02-05 naming-standards rename (for example
  `SELECT l_name FROM sqlite_master` in `SIMPLE_SQL_SCHEMA.tables`, where the column is `name`). Since 1.3.0
  those queries report a compile error instead of raising a precondition violation, so 8 of the 40 fail on
  an assertion instead of an exception.

### Also included (previously unreleased)
- Class invariants are O(1) again: clauses that built an MML model (`x_model.count = count`) or walked a collection on every feature call were removed. An invariant runs on every call, so those made each call O(n) and any loop over the object O(n^2); simple_json read a 1434-element array in 158 s under DBC before the fix. Model and per-element facts stay in the postconditions of the features that establish them.
- Testing config updates, AutoTest fixes, .gitignore cleanup
- Add SCOOP concurrency capability
- Migrate to simple_testing library
- Replace hardcoded paths with environment variables
- new target for profiling
- Strengthened DBC Contracts
- more updates
- Assessment update
- AI Productivity Assessment-Comparison
- Phase 6 work on WMS

## [1.0.0] - 2025-12-08

### Added
- Initial release
- Core functionality implemented
- Test suite with comprehensive coverage
- Documentation and examples

[1.3.2]: https://github.com/simple-eiffel/simple_sql/compare/v1.0.0...fix/debate-defects
[1.0.0]: https://github.com/simple-eiffel/simple_sql/releases/tag/v1.0.0
