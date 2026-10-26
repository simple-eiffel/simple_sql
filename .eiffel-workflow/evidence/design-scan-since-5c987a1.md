# Design Scan (diff mode): simple_sql, since 5c987a1
# Date: 2026-10-26
# Subjects: src/simple_sql_schema.e (user_version_of added, lines 326-345); testing files read for coverage
# Compared against: all of src/ (grep of PRAGMA and sqlite_master across src)
# Read-only: no compile, no source edits

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction / drift | 4 | 1 | 2 | 1 |
| Contracts | 2 | 0 | 1 | 1 |
| MI / Generics | 0 | 0 | 0 | 0 |
| **Total** | **6** | **1** | **3** | **2** |

## Findings

| # | Priority | Category | Location | Opportunity |
|---|----------|----------|----------|-------------|
| 1 | HIGH | D1 drift | src/simple_sql_schema.e, src/simple_sql_fts5.e, src/simple_sql_fts5_query.e | Same unqualified-PRAGMA / sqlite_master defect on attached schemas remains in the rest of the introspection API |
| 2 | MEDIUM | A5 | src/simple_sql_schema.e:310-324, 326-345, 362-376 | Three copies of "run a PRAGMA, read first row, one integer column"; a private helper is warranted |
| 3 | MEDIUM | A4 | src/simple_sql_schema.e:326-345 | user_version_of has no postcondition and cannot tell an error from stamp 0 |
| 4 | MEDIUM | D1 / asymmetry | src/simple_sql_schema.e:347-360 | set_user_version is main-only; no attached counterpart, and nothing says so |
| 5 | LOW | A4 | src/simple_sql_schema.e:310-324 | user_version (the main reader) has no contracts at all |
| 6 | LOW | cost | src/simple_sql_schema.e:333, src/simple_sql_database.e:650-663 | precondition is_attached runs a full PRAGMA database_list query on every call |

## Detailed Findings

### Finding 1: the unqualified-PRAGMA defect is not confined to user_version
**Priority:** HIGH
**Category:** D1 (drift: the fixed copy and its siblings now disagree)
**Description:** The change fixes exactly one reader. Every other schema reader still issues an unqualified PRAGMA or reads sqlite_master, which SQLite resolves against main (for table_info / index_list / foreign_key_list an unqualified name searches main, then temp, then attachments in attach order, so a same-named table in main shadows a pack's). A client holding a read-only pack gets main's answer, or no answer for a pack-only table. Same class of defect as simple_bible finding 3.3.
**Evidence (src/simple_sql_schema.e):**
- line 64: tables list, SELECT ... FROM sqlite_master (main only)
- line 86: views list, sqlite_master
- line 106: table_exists, sqlite_master
- line 121: view_exists, sqlite_master
- lines 180, 201: columns / column_names, PRAGMA table_info('t')
- line 230: indexes, PRAGMA index_list
- line 277: foreign_keys, PRAGMA foreign_key_list
- line 319: user_version (main by design; see finding 2)
- line 371: schema_version, PRAGMA schema_version (main only; same defect as user_version, no _of twin)
- lines 388, 408, 441, 468: load_columns / load_indexes / load_index_columns / load_foreign_keys, so table_info (line 128) is also main-only
**Evidence (other classes):**
- src/simple_sql_fts5.e:58 (FTS5 table existence, sqlite_master), :552 (column_index, PRAGMA table_info)
- src/simple_sql_fts5_query.e:747 (column_index, PRAGMA table_info)
- src/simple_sql_audit.e:104, 254, 675, 732, 780 (trigger lookup in sqlite_master)
- src/simple_sql_quick.e:221 (table existence)
- src/simple_sql_backup.e:128-172 and src/simple_sql_export.e:413 (sqlite_master; main by intent for backup, arguably correct)
**Not defects:** simple_sql_pragma_config.e:251-270 (connection-wide settings; main is the right target, and foreign_keys / busy_timeout are connection-level anyway); simple_sql_database.e:657 (database_list is already global); simple_sql_migration_runner.e:62 and :438 (migrations target main by design).
**Suggested Action:** Decide the scope with Larry before extending. Two shapes:
1. Minimal: add `schema_version_of (a_schema)` (same defect, same fix) and `table_exists_in (a_table, a_schema)`; leave the rest and document "main only" in each header comment.
2. Systematic: give SIMPLE_SQL_SCHEMA an optional `schema_name: READABLE_STRING_8` (default "main", set via a `make_for (db, schema)` creation procedure) and route every PRAGMA / sqlite_master query through one private `qualified` helper and a `master_table` helper. Then user_version_of becomes unnecessary and the whole API works on a pack. Needs invariant `schema_name_valid: is_main or database.is_valid_schema_name (schema_name)`.
Also note main-shadowing: with an attached pack, `columns ("t")` may today silently return main's `t`.
**Effort:** option 1: 2 features; option 2: about 14 query sites plus 1 creation procedure.

### Finding 2: three copies of the one-integer PRAGMA read
**Priority:** MEDIUM (A5 normally ranks HIGH; lowered because each copy is 5 lines)
**Category:** A5 duplicated bodies
**Evidence:** identical nesting `attached database.query (...) as al_l_result` / `not rows.is_empty and then attached rows.first as al_l_row` / `Result := al_l_row.integer_value ("<column>")` at src/simple_sql_schema.e:319-323 (user_version), :340-344 (user_version_of), :371-375 (schema_version). Only the SQL text and the column name differ, and the column name always equals the pragma name.
**Description:** Yes, a shared private helper is warranted, and the third copy (schema_version) is the reason. Suggested, in `feature {NONE} -- Implementation`:
```
pragma_integer (a_sql, a_column: READABLE_STRING_8): INTEGER
    -- First-row integer of a_sql, read from column a_column; 0 when absent.
```
user_version calls `pragma_integer ("PRAGMA user_version", "user_version")`, user_version_of calls `pragma_integer ("PRAGMA " + a_schema + ".user_version", "user_version")`, schema_version likewise. The two-argument form avoids deriving the column name from the SQL text. A shared helper also gives one place to implement finding 3 (error handling).
Do not collapse user_version into `user_version_of ("main")`: the precondition `is_valid_schema_name` rejects main (simple_sql_database.e:671-673).
**Effort:** 1 new private feature, 3 bodies shortened.

### Finding 3: user_version_of contract gaps and silent failure
**Priority:** MEDIUM
**Category:** A4 missing contracts
**Evidence:** src/simple_sql_schema.e:326-345. The require clause (is_open, valid_schema_name, is_attached) is good. There is no ensure. If `database.query` reports an error, or the row is absent, Result stays 0, which is also a legitimate stamp. A caller cannot tell "pack is unstamped" from "query failed", the very case a pack check exists to catch.
**Suggested fix:** add `ensure non_negative: Result >= 0` (the library already states this law for the setter at line 347-352, `version_non_negative`). Then pick one failure signal in the shared helper: return -1 and document `ensure unreadable_is_minus_one` tied to `database.has_error`, or expose a status query. SIMPLE_SQL_SCHEMA currently reports no read errors anywhere, so decide once, in the helper from finding 2. If -1 is chosen, the non_negative postcondition must become `Result >= -1`.
**Effort:** 1 to 2 lines per feature.

### Finding 4: set_user_version has no attached counterpart
**Priority:** MEDIUM
**Category:** D1 asymmetry
**Evidence:** src/simple_sql_schema.e:347-360 writes `PRAGMA user_version = n` (main only); the read side now has user_version_of at :326. attach_read_only (src/simple_sql_database.e:609) is the only attach API, and a read-only pack cannot be stamped, so this is a design note, not a bug.
**Suggested fix:** state in the header comment of set_user_version "main only; packs attached with attach_read_only cannot be stamped". Add `set_user_version_of` only if a writable attach API appears.
**Effort:** 1 comment line.

### Finding 5: user_version has no contracts
**Priority:** LOW
**Evidence:** src/simple_sql_schema.e:310-324: no `require is_open`, no `ensure non_negative`. The new sibling has a require, so the pair now disagrees.
**Suggested fix:** add `require is_open: database.is_open` and `ensure non_negative: Result >= 0`.
**Effort:** 2 lines.

### Finding 6: precondition cost
**Priority:** LOW
**Evidence:** src/simple_sql_schema.e:333 `database.is_attached (a_schema)` calls src/simple_sql_database.e:650-663, which builds a SIMPLE_SQL_RESULT from PRAGMA database_list and scans all rows. Test builds keep contracts, so each call pays this. Fine for a one-time pack check; wasteful if a client polls in a loop. Per the timing-trumps-contracts rule, keep it and leave a dated note; revisit only if a caller appears in a hot path.
**Effort:** none now.

## Test notes (testing/test_simple_sql_integrity.e:378-399, testing/test_app.e:127)
- Covers the happy path (main 7, pack 3, main unchanged afterwards); registered in test_app.e.
- Not covered: a mixed-case schema name ("PACK"; is_attached is case-insensitive, SQLite schema names are too), an unstamped pack (expect 0), and finding 3's error path. The first two are cheap to add.

## Recommended Order
1. Finding 1 decision (scope): it determines whether user_version_of survives as is or is subsumed by a schema-scoped SIMPLE_SQL_SCHEMA.
2. Findings 2 and 3 together (one helper carries the error behavior).
3. Findings 5 and 4 (contract and comment touch-ups).
4. Finding 6 only if profiling asks.
