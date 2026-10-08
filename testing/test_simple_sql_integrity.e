note
	description: "[
		Error-integrity tests (fork 02 F-9 items a-d, f-i), read-only ATTACH (D4),
		URI read-only attach (D7) and the linked engine (D5, D19) as seen through simple_sql.
	]"
	testing: "covers"
	testing: "execution/serial"

class
	TEST_SIMPLE_SQL_INTEGRITY

inherit
	TEST_SET_BASE

feature -- Test: (a) execute_with_args reports failure

	test_execute_with_args_reports_failure
			-- A failing execute_with_args sets has_error with SQLite's message.
		local
			db: SIMPLE_SQL_DATABASE
		do
			db := fresh_memory
			db.execute_with_args ("INSERT INTO q (id) VALUES (?)", <<{INTEGER_64} 100>>)
			assert_true ("error_reported", db.has_error)
			assert_true ("constraint", db.is_constraint_error)
			assert_true ("message_kept", attached db.last_error_message as m and then m.has_substring ("UNIQUE"))
			db.execute_with_args ("INSERT INTO q (id) VALUES (?)", <<{INTEGER_64} 101>>)
			assert_false ("success_clears_outside_transaction", db.has_error)
			db.close
		end

	test_prepared_statement_execute_reports_failure
			-- SIMPLE_SQL_PREPARED_STATEMENT.execute on a modification sets last_error.
		local
			db: SIMPLE_SQL_DATABASE
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
		do
			db := fresh_memory
			l_stmt := db.prepare ("INSERT INTO q (id) VALUES (?)")
			l_stmt.bind_integer (1, 100)
			l_stmt.execute
			assert_true ("statement_error", l_stmt.has_error)
			l_stmt.reset
			l_stmt.bind_integer (1, 102)
			l_stmt.execute
			assert_false ("statement_ok", l_stmt.has_error)
			assert_integers_equal ("row_added", 2, count_of (db, "SELECT count(*) FROM q"))
			db.close
		end

feature -- Test: (b) sticky errors inside a transaction

	test_errors_sticky_in_transaction
			-- After a failed statement inside a transaction, has_error stays True.
		local
			db: SIMPLE_SQL_DATABASE
		do
			db := fresh_memory
			db.begin_transaction
			db.execute ("INSERT INTO q (id) VALUES (1)")
			assert_false ("first_ok", db.has_error)
			db.execute ("INSERT INTO q (id) VALUES (100)")
			assert_true ("failure", db.has_error)
			db.execute ("INSERT INTO q (id) VALUES (3)")
			assert_true ("still_failed_after_success", db.has_error)
			assert_true ("transaction_failed", db.is_transaction_failed)
			db.rollback
			assert_false ("transaction_over", db.is_in_transaction)
			assert_false ("not_failed_any_more", db.is_transaction_failed)
			db.close
		end

feature -- Test: (c) atomic

	test_atomic_rolls_back_on_middle_failure
			-- atomic with a failing middle `execute' commits nothing and reports the failure.
		local
			db: SIMPLE_SQL_DATABASE
		do
			db := fresh_memory
			db.atomic (agent three_inserts (db, False))
			assert_true ("reported", db.has_error)
			assert_true ("message", attached db.last_error_message as m and then m.has_substring ("UNIQUE"))
			assert_false ("not_in_transaction", db.is_in_transaction)
			assert_integers_equal ("nothing_committed", 0, count_of (db, "SELECT count(*) FROM q WHERE id IN (1, 3)"))
			db.close
		end

	test_atomic_rolls_back_execute_with_args_failure
			-- The same with execute_with_args.
		local
			db: SIMPLE_SQL_DATABASE
		do
			db := fresh_memory
			db.atomic (agent three_inserts (db, True))
			assert_true ("reported", db.has_error)
			assert_integers_equal ("nothing_committed", 0, count_of (db, "SELECT count(*) FROM q WHERE id IN (1, 3)"))
			db.close
		end

	test_atomic_commits_when_clean
			-- atomic commits when every statement succeeds.
		local
			db: SIMPLE_SQL_DATABASE
		do
			db := fresh_memory
			db.atomic (agent (a_db: SIMPLE_SQL_DATABASE)
				do
					a_db.execute ("INSERT INTO q (id) VALUES (1)")
					a_db.execute_with_args ("INSERT INTO q (id) VALUES (?)", <<{INTEGER_64} 2>>)
				end (db))
			assert_false ("no_error", db.has_error)
			assert_integers_equal ("committed", 2, count_of (db, "SELECT count(*) FROM q WHERE id IN (1, 2)"))
			db.close
		end

	test_atomic_rolls_back_on_exception
			-- An exception inside the agent rolls back and is reported.
		local
			db: SIMPLE_SQL_DATABASE
		do
			db := fresh_memory
			db.atomic (agent (a_db: SIMPLE_SQL_DATABASE)
				do
					a_db.execute ("INSERT INTO q (id) VALUES (1)")
					(create {DEVELOPER_EXCEPTION}).raise
				end (db))
			assert_true ("reported", db.has_error)
			assert_false ("not_in_transaction", db.is_in_transaction)
			assert_integers_equal ("nothing_committed", 0, count_of (db, "SELECT count(*) FROM q WHERE id = 1"))
			db.close
		end

feature -- Test: (d) commit

	test_commit_of_failed_transaction_rolls_back
			-- Manual begin / failing middle statement / commit: nothing committed, failure reported.
		local
			db: SIMPLE_SQL_DATABASE
		do
			db := fresh_memory
			db.begin_transaction
			three_inserts (db, False)
			db.commit
			assert_true ("reported", db.has_error)
			assert_false ("not_in_transaction", db.is_in_transaction)
			assert_integers_equal ("nothing_committed", 0, count_of (db, "SELECT count(*) FROM q WHERE id IN (1, 3)"))
			db.close
		end

	test_commit_failure_reported
			-- A COMMIT that fails (deferred foreign key) is reported and leaves the transaction open.
		local
			db: SIMPLE_SQL_DATABASE
		do
			create db.make_memory
			db.execute ("PRAGMA foreign_keys = ON")
			db.execute ("CREATE TABLE p (id INTEGER PRIMARY KEY)")
			db.execute ("CREATE TABLE c (pid INTEGER REFERENCES p (id) DEFERRABLE INITIALLY DEFERRED)")
			db.begin_transaction
			db.execute ("INSERT INTO c (pid) VALUES (42)")
			assert_false ("deferred_insert_ok", db.has_error)
			db.commit_transaction
			assert_true ("commit_failure_reported", db.has_error)
			assert_true ("still_open", db.is_in_transaction)
			db.rollback_transaction
			assert_true ("error_kept_through_rollback", db.has_error)
			assert_false ("closed_transaction", db.is_in_transaction)
			assert_integers_equal ("nothing_kept", 0, count_of (db, "SELECT count(*) FROM c"))
			db.close
		end

	test_close_after_failed_commit
			-- close works with a transaction left open by a failed COMMIT.
		local
			db: SIMPLE_SQL_DATABASE
		do
			create db.make_memory
			db.execute ("PRAGMA foreign_keys = ON")
			db.execute ("CREATE TABLE p (id INTEGER PRIMARY KEY)")
			db.execute ("CREATE TABLE c (pid INTEGER REFERENCES p (id) DEFERRABLE INITIALLY DEFERRED)")
			db.begin_transaction
			db.execute ("INSERT INTO c (pid) VALUES (42)")
			db.commit
			assert_true ("still_open", db.is_in_transaction)
			db.close
			assert_false ("closed", db.is_open)
		end

feature -- Test: (f) rollback keeps the error

	test_rollback_keeps_error
			-- rollback_transaction does not erase the error the caller is about to read.
		local
			db: SIMPLE_SQL_DATABASE
		do
			db := fresh_memory
			db.begin_transaction
			db.execute ("INSERT INTO q (id) VALUES (100)")
			db.rollback_transaction
			assert_true ("error_kept", db.has_error)
			assert_true ("message_kept", attached db.last_error_message as m and then m.has_substring ("UNIQUE"))
			db.close
		end

feature -- Test: (g) migration runner

	test_migration_middle_failure_rolled_back
			-- A migration whose MIDDLE statement fails returns False, is not stamped, leaves nothing,
			-- and keeps SQLite's message.
		local
			db: SIMPLE_SQL_DATABASE
			l_runner: SIMPLE_SQL_MIGRATION_RUNNER
		do
			create db.make_memory
			create l_runner.make (db)
			l_runner.add (create {TEST_MIGRATION_MID_FAIL})
			assert_false ("migrate_false", l_runner.migrate)
			assert_integers_equal ("version_unchanged", 0, count_of (db, "PRAGMA user_version"))
			assert_integers_equal ("m1_absent", 0, count_of (db, "SELECT count(*) FROM sqlite_master WHERE name = 'm1'"))
			assert_integers_equal ("m2_absent", 0, count_of (db, "SELECT count(*) FROM sqlite_master WHERE name = 'm2'"))
			assert_string_contains ("sqlite_message", l_runner.last_error, "UNIQUE constraint failed")
			assert_false ("not_in_transaction", db.is_in_transaction)
			db.close
		end

	test_migration_last_failure_keeps_message
			-- A migration whose LAST statement fails keeps SQLite's message (it was "Migration 1 failed").
		local
			db: SIMPLE_SQL_DATABASE
			l_runner: SIMPLE_SQL_MIGRATION_RUNNER
		do
			create db.make_memory
			create l_runner.make (db)
			l_runner.add (create {TEST_MIGRATION_LAST_FAIL})
			assert_false ("migrate_false", l_runner.migrate)
			assert_string_contains ("sqlite_message", l_runner.last_error, "UNIQUE constraint failed")
			assert_integers_equal ("version_unchanged", 0, count_of (db, "PRAGMA user_version"))
			db.close
		end

feature -- Test: (h) close after a compile failure

	test_close_after_compile_failure
			-- execute and query of SQL that fails to compile report the error and leave close working.
		local
			db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create db.make_memory
			db.execute ("INSERT INTO missing_table (x) VALUES (1)")
			assert_true ("execute_error", db.has_error)
			assert_true ("execute_message", attached db.last_error_message as m and then m.has_substring ("no such table"))
			l_result := db.query ("SELECT * FROM missing_table")
			assert_true ("query_error", db.has_error)
			assert_true ("query_empty", l_result.is_empty)
			db.execute_with_args ("INSERT INTO missing_table (x) VALUES (?)", <<{INTEGER_64} 1>>)
			assert_true ("args_error", db.has_error)
			db.close
			assert_false ("closed", db.is_open)
		end

feature -- Test: (i) online backup retries BUSY/LOCKED

	test_backup_retries_busy_source
			-- A step refused with SQLITE_BUSY is retried; the backup completes once the lock is gone.
		local
			l_source, l_locker, l_dest: SIMPLE_SQL_DATABASE
			l_backup: SIMPLE_SQL_ONLINE_BACKUP
		do
			delete_file ("integrity_backup_src.db")
			create l_source.make ("integrity_backup_src.db")
			l_source.execute ("CREATE TABLE t (id INTEGER)")
			l_source.execute ("INSERT INTO t (id) VALUES (1)")
			create l_locker.make ("integrity_backup_src.db")
			l_locker.execute ("BEGIN EXCLUSIVE")
			assert_false ("exclusive_taken", l_locker.has_error)
			create l_dest.make_memory
			create l_backup.make (l_source, l_dest)
			l_backup.set_busy_retry (50, 1)
			l_backup.set_busy_retry_callback (agent release_on_third (?, l_locker))
			l_backup.execute
			assert_true ("complete", l_backup.is_complete)
			assert_integers_equal ("retried_three_times", 3, l_backup.busy_retries_done)
			assert_integers_equal ("copied", 1, count_of (l_dest, "SELECT count(*) FROM t"))
			l_dest.close
			l_locker.close
			l_source.close
			delete_file ("integrity_backup_src.db")
		end

	test_backup_gives_up_after_retry_budget
			-- With the lock never released, the backup stops after the retry budget and reports BUSY.
		local
			l_source, l_locker, l_dest: SIMPLE_SQL_DATABASE
			l_backup: SIMPLE_SQL_ONLINE_BACKUP
		do
			delete_file ("integrity_backup_src2.db")
			create l_source.make ("integrity_backup_src2.db")
			l_source.execute ("CREATE TABLE t (id INTEGER)")
			create l_locker.make ("integrity_backup_src2.db")
			l_locker.execute ("BEGIN EXCLUSIVE")
			create l_dest.make_memory
			create l_backup.make (l_source, l_dest)
			l_backup.set_busy_retry (3, 1)
			l_backup.execute
			assert_false ("not_complete", l_backup.is_complete)
			assert_true ("had_error", l_backup.had_error)
			assert_integers_equal ("busy_code", 5, l_backup.last_error_code & 0xFF)
			assert_integers_equal ("budget_used", 3, l_backup.busy_retries_done)
			l_locker.execute ("ROLLBACK")
			l_dest.close
			l_locker.close
			l_source.close
			delete_file ("integrity_backup_src2.db")
		end

feature -- Test: D4 / D7 read-only attach

	test_attach_read_only_on_read_only_connection
			-- attach_read_only works on a make_read_only connection, and the attachment stays read-only.
		local
			db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			make_fixture ("integrity_main.db")
			make_fixture ("integrity_pack.db")
			create db.make_read_only ("integrity_main.db")
			db.attach_read_only ("integrity_pack.db", "pack")
			assert_false ("attached_without_error", db.has_error)
			assert_true ("is_attached", db.is_attached ("pack"))
			assert_integers_equal ("read_ok", 1, count_of (db, "SELECT count(*) FROM pack.t"))
				-- `execute' needs a writable connection; `query' does not, so it probes the attachment.
			l_result := db.query ("INSERT INTO pack.t (id) VALUES (2)")
			assert_true ("write_refused", db.has_error)
			assert_true ("readonly_error", db.is_readonly_error)
			db.detach ("pack")
			assert_false ("detached", db.is_attached ("pack"))
			db.close
			assert_integers_equal ("pack_unchanged", 1, count_in_file ("integrity_pack.db"))
			delete_file ("integrity_main.db")
			delete_file ("integrity_pack.db")
		end

	test_attach_read_only_on_writable_connection
			-- On a read-write connection the attachment is read-only and main stays writable.
		local
			db: SIMPLE_SQL_DATABASE
		do
			make_fixture ("integrity_pack2.db")
			db := fresh_memory
			db.attach_read_only ("integrity_pack2.db", "pack")
			assert_false ("attached", db.has_error)
			db.execute ("INSERT INTO pack.t (id) VALUES (2)")
			assert_true ("attachment_write_refused", db.has_error)
			assert_true ("readonly_error", db.is_readonly_error)
			db.execute ("INSERT INTO q (id) VALUES (5)")
			assert_false ("main_still_writable", db.has_error)
			db.close
			assert_integers_equal ("pack_unchanged", 1, count_in_file ("integrity_pack2.db"))
			delete_file ("integrity_pack2.db")
		end

	test_attach_read_only_missing_file_errors
			-- A missing file is reported and not created.
		local
			db: SIMPLE_SQL_DATABASE
		do
			delete_file ("integrity_missing.db")
			db := fresh_memory
			db.attach_read_only ("integrity_missing.db", "gone")
			assert_true ("error", db.has_error)
			assert_false ("not_attached", db.is_attached ("gone"))
			db.close
			assert_false ("not_created", (create {RAW_FILE}.make_with_name ("integrity_missing.db")).exists)
		end

	test_read_only_uri_encoding
			-- The URI is percent-encoded and Windows drive paths use file:///X:/...
		local
			db: SIMPLE_SQL_DATABASE
		do
			create db.make_memory
			assert_strings_equal ("relative", "file:a%%20b%%23c.db?mode=ro", db.read_only_uri ("a b#c.db"))
			assert_strings_equal ("drive", "file:///C:/data/x%%3F.db?mode=ro", db.read_only_uri ("C:\data\x?.db"))
			assert_strings_equal ("quote", "file:o%%27k.db?mode=ro", db.read_only_uri ("o'k.db"))
			db.close
		end

	test_raw_uri_attach_mode_ro_is_read_only
			-- D7 through simple_sql: ATTACH 'file:...?mode=ro' by plain SQL attaches read-only.
		local
			db: SIMPLE_SQL_DATABASE
		do
			make_fixture ("integrity_uri.db")
			db := fresh_memory
			db.execute ("ATTACH DATABASE 'file:integrity_uri.db?mode=ro' AS u")
			assert_false ("attached", db.has_error)
			db.execute ("INSERT INTO u.t (id) VALUES (9)")
			assert_true ("write_refused", db.has_error)
			db.close
			delete_file ("integrity_uri.db")
		end

feature -- Test: D5 / D19 engine

	test_engine_is_3_53_4
			-- simple_sql links SQLite 3.53.4.
		local
			db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create db.make_memory
			l_result := db.query ("SELECT sqlite_version() AS v")
			assert_strings_equal ("version", "3.53.4", l_result.first.string_value ("v"))
			db.close
		end

	test_foreign_key_check_reports_violation_with_parent_in_attachment
			-- A bare PRAGMA foreign_key_check reports a main-table violation even when an attached file
			-- holds a table of the parent's name (3.31.1 resolved the parent there and passed).
		local
			db: SIMPLE_SQL_DATABASE
			l_parent: SIMPLE_SQL_DATABASE
		do
			delete_file ("integrity_fk_parent.db")
			create l_parent.make ("integrity_fk_parent.db")
			l_parent.execute ("CREATE TABLE parent (id INTEGER PRIMARY KEY)")
			l_parent.execute ("INSERT INTO parent (id) VALUES (7)")
			l_parent.close
			create db.make_memory
			db.execute ("CREATE TABLE item (id INTEGER PRIMARY KEY, pid INTEGER REFERENCES parent (id))")
			db.execute ("INSERT INTO item (id, pid) VALUES (1, 7)")
			assert_integers_equal ("before_attach", 1, db.query ("PRAGMA foreign_key_check").count)
			db.attach_read_only ("integrity_fk_parent.db", "p")
			assert_false ("attached", db.has_error)
			assert_integers_equal ("bare_check_still_reports", 1, db.query ("PRAGMA foreign_key_check").count)
			assert_integers_equal ("main_check_reports", 1, db.query ("PRAGMA main.foreign_key_check").count)
			db.close
			delete_file ("integrity_fk_parent.db")
		end

feature {NONE} -- Helpers

	fresh_memory: SIMPLE_SQL_DATABASE
			-- In-memory database with table q (id PRIMARY KEY) holding row 100.
		do
			create Result.make_memory
			Result.execute ("CREATE TABLE q (id INTEGER PRIMARY KEY)")
			Result.execute ("INSERT INTO q (id) VALUES (100)")
		end

	three_inserts (a_db: SIMPLE_SQL_DATABASE; a_with_args: BOOLEAN)
			-- Insert 1, 100 (duplicate: fails), 3.
		do
			if a_with_args then
				a_db.execute_with_args ("INSERT INTO q (id) VALUES (?)", <<{INTEGER_64} 1>>)
				a_db.execute_with_args ("INSERT INTO q (id) VALUES (?)", <<{INTEGER_64} 100>>)
				a_db.execute_with_args ("INSERT INTO q (id) VALUES (?)", <<{INTEGER_64} 3>>)
			else
				a_db.execute ("INSERT INTO q (id) VALUES (1)")
				a_db.execute ("INSERT INTO q (id) VALUES (100)")
				a_db.execute ("INSERT INTO q (id) VALUES (3)")
			end
		end

	release_on_third (a_retry: INTEGER; a_locker: SIMPLE_SQL_DATABASE)
			-- Release `a_locker''s exclusive lock at the third retry.
		do
			if a_retry = 3 then
				a_locker.execute ("ROLLBACK")
			end
		end

	count_of (a_db: SIMPLE_SQL_DATABASE; a_sql: READABLE_STRING_8): INTEGER
			-- First column of the first row of `a_sql' as an integer (-1 if none).
		local
			l_result: SIMPLE_SQL_RESULT
		do
			Result := -1
			l_result := a_db.query (a_sql)
			if not l_result.is_empty and then attached {INTEGER_64} l_result.first [1] as v then
				Result := v.to_integer_32
			end
		end

	count_in_file (a_name: STRING_8): INTEGER
			-- Rows of table t in database file `a_name'.
		local
			db: SIMPLE_SQL_DATABASE
		do
			create db.make_read_only (a_name)
			Result := count_of (db, "SELECT count(*) FROM t")
			db.close
		end

	make_fixture (a_name: STRING_8)
			-- Database file `a_name' with table t holding one row.
		local
			db: SIMPLE_SQL_DATABASE
		do
			delete_file (a_name)
			create db.make (a_name)
			db.execute ("CREATE TABLE t (id INTEGER PRIMARY KEY)")
			db.execute ("INSERT INTO t (id) VALUES (1)")
			db.close
		end

	delete_file (a_name: STRING_8)
			-- Delete file `a_name' if present.
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_name (a_name)
			if l_file.exists then
				l_file.delete
			end
		end

end
