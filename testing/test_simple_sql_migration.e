note
	description: "Tests for SIMPLE_SQL_MIGRATION and SIMPLE_SQL_MIGRATION_RUNNER"
	testing: "type/manual"
	testing: "execution/serial"

class
	TEST_SIMPLE_SQL_MIGRATION

inherit
	TEST_SET_BASE

feature -- Test routines: Migration Runner Setup

	test_runner_initial_state
			-- Test runner initial state
		local
			l_db: SIMPLE_SQL_DATABASE
			l_runner: SIMPLE_SQL_MIGRATION_RUNNER
		do
			create l_db.make_memory

			create l_runner.make (l_db)

			assert_equal ("current_zero", 0, l_runner.current_version)
			assert_equal ("latest_zero", 0, l_runner.latest_version)
			assert_true ("is_current", l_runner.is_current)
			assert_false ("no_pending", l_runner.has_pending)

			l_db.close
		end

	test_runner_add_migrations
			-- Test adding migrations
		local
			l_db: SIMPLE_SQL_DATABASE
			l_runner: SIMPLE_SQL_MIGRATION_RUNNER
		do
			create l_db.make_memory

			create l_runner.make (l_db)
			l_runner.add (create {TEST_MIGRATION_001})
			l_runner.add (create {TEST_MIGRATION_002})

			assert_equal ("latest_2", 2, l_runner.latest_version)
			assert_true ("has_pending", l_runner.has_pending)
			assert_equal ("pending_count", 2, l_runner.pending_migrations.count)

			l_db.close
		end

	test_runner_sorted_order
			-- Test migrations are sorted by version
		local
			l_db: SIMPLE_SQL_DATABASE
			l_runner: SIMPLE_SQL_MIGRATION_RUNNER
		do
			create l_db.make_memory

			create l_runner.make (l_db)
			-- Add out of order
			l_runner.add (create {TEST_MIGRATION_002})
			l_runner.add (create {TEST_MIGRATION_001})

			-- Should be sorted
			assert_equal ("first_is_1", 1, l_runner.migrations [1].version)
			assert_equal ("second_is_2", 2, l_runner.migrations [2].version)

			l_db.close
		end

feature -- Test routines: Migration Execution

	test_migrate_all
			-- Test running all migrations
		local
			l_db: SIMPLE_SQL_DATABASE
			l_runner: SIMPLE_SQL_MIGRATION_RUNNER
			l_schema: SIMPLE_SQL_SCHEMA
		do
			create l_db.make_memory

			create l_runner.make (l_db)
			l_runner.add (create {TEST_MIGRATION_001})
			l_runner.add (create {TEST_MIGRATION_002})

			assert_true ("migrate_success", l_runner.migrate)
			assert_equal ("version_2", 2, l_runner.current_version)
			assert_true ("is_current", l_runner.is_current)

			-- Verify tables exist
			create l_schema.make (l_db)
			assert_true ("users_exists", l_schema.table_exists ("users"))
			assert_true ("posts_exists", l_schema.table_exists ("posts"))

			l_db.close
		end

	test_migrate_one
			-- Test running single migration
		local
			l_db: SIMPLE_SQL_DATABASE
			l_runner: SIMPLE_SQL_MIGRATION_RUNNER
		do
			create l_db.make_memory

			create l_runner.make (l_db)
			l_runner.add (create {TEST_MIGRATION_001})
			l_runner.add (create {TEST_MIGRATION_002})

			assert_true ("migrate_one_success", l_runner.migrate_one)
			assert_equal ("version_1", 1, l_runner.current_version)
			assert_equal ("one_pending", 1, l_runner.pending_migrations.count)

			l_db.close
		end

	test_migrate_to_version
			-- Test migrating to specific version
		local
			l_db: SIMPLE_SQL_DATABASE
			l_runner: SIMPLE_SQL_MIGRATION_RUNNER
		do
			create l_db.make_memory

			create l_runner.make (l_db)
			l_runner.add (create {TEST_MIGRATION_001})
			l_runner.add (create {TEST_MIGRATION_002})
			l_runner.add (create {TEST_MIGRATION_003})

			assert_true ("migrate_to_2", l_runner.migrate_to (2))
			assert_equal ("at_version_2", 2, l_runner.current_version)

			l_db.close
		end

feature -- Test routines: Rollback

	test_rollback
			-- Test rolling back last migration
		local
			l_db: SIMPLE_SQL_DATABASE
			l_runner: SIMPLE_SQL_MIGRATION_RUNNER
			l_schema: SIMPLE_SQL_SCHEMA
		do
			create l_db.make_memory

			create l_runner.make (l_db)
			l_runner.add (create {TEST_MIGRATION_001})
			l_runner.add (create {TEST_MIGRATION_002})
			assert_true ("migrate_success", l_runner.migrate)

			assert_true ("rollback_success", l_runner.rollback)
			assert_equal ("version_1", 1, l_runner.current_version)

			-- Verify posts table was dropped
			create l_schema.make (l_db)
			assert_false ("posts_gone", l_schema.table_exists ("posts"))
			assert_true ("users_still_there", l_schema.table_exists ("users"))

			l_db.close
		end

	test_rollback_all
			-- Test rolling back all migrations
		local
			l_db: SIMPLE_SQL_DATABASE
			l_runner: SIMPLE_SQL_MIGRATION_RUNNER
			l_schema: SIMPLE_SQL_SCHEMA
		do
			create l_db.make_memory

			create l_runner.make (l_db)
			l_runner.add (create {TEST_MIGRATION_001})
			l_runner.add (create {TEST_MIGRATION_002})
			assert_true ("migrate_success", l_runner.migrate)

			assert_true ("rollback_all_success", l_runner.rollback_all)
			assert_equal ("version_0", 0, l_runner.current_version)

			-- Verify all tables gone
			create l_schema.make (l_db)
			assert_false ("users_gone", l_schema.table_exists ("users"))
			assert_false ("posts_gone", l_schema.table_exists ("posts"))

			l_db.close
		end

	test_reset
			-- Test reset (rollback all + migrate all)
		local
			l_db: SIMPLE_SQL_DATABASE
			l_runner: SIMPLE_SQL_MIGRATION_RUNNER
		do
			create l_db.make_memory

			create l_runner.make (l_db)
			l_runner.add (create {TEST_MIGRATION_001})
			l_runner.add (create {TEST_MIGRATION_002})
			assert_true ("migrate_success", l_runner.migrate)

			-- Add some data
			l_db.execute ("INSERT INTO users (name) VALUES ('Alice')")

			assert_true ("reset_success", l_runner.reset)
			assert_equal ("at_latest", 2, l_runner.current_version)

			-- Data should be gone (fresh start)
			if attached l_db.query ("SELECT COUNT(*) as cnt FROM users") as l_result then
				assert_equal ("no_data", 0, l_result.first.integer_value ("cnt"))
			end

			l_db.close
		end

feature -- Test routines: Error Handling

	test_has_version_check
			-- Test has_version prevents duplicates
		local
			l_db: SIMPLE_SQL_DATABASE
			l_runner: SIMPLE_SQL_MIGRATION_RUNNER
		do
			create l_db.make_memory

			create l_runner.make (l_db)
			l_runner.add (create {TEST_MIGRATION_001})

			assert_true ("has_version_1", l_runner.has_version (1))
			assert_false ("no_version_99", l_runner.has_version (99))

			l_db.close
		end

	test_no_error_on_success
			-- Test no error flag on successful migration
		local
			l_db: SIMPLE_SQL_DATABASE
			l_runner: SIMPLE_SQL_MIGRATION_RUNNER
		do
			create l_db.make_memory

			create l_runner.make (l_db)
			l_runner.add (create {TEST_MIGRATION_001})
			assert_true ("migrate_success", l_runner.migrate)

			assert_false ("no_error", l_runner.has_error)

			l_db.close
		end

feature -- Test routines: Edge Cases (Priority 4)

	test_migration_partial_failure
			-- Test migration fails mid-execution (rollback should occur)
			-- Note: Don't close database after error - may be locked
		note
			testing: "covers/{SIMPLE_SQL_MIGRATION_RUNNER}.migrate"
			testing: "edge_case"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_runner: SIMPLE_SQL_MIGRATION_RUNNER
		do
			create l_db.make_memory

			create l_runner.make (l_db)
			l_runner.add (create {TEST_MIGRATION_001})
			l_runner.add (create {TEST_MIGRATION_FAIL})  -- This will fail

			-- Migration should fail
			assert_false ("migrate_fails", l_runner.migrate)
			assert_true ("has_error", l_runner.has_error)

			-- Check version - should be at v1 (successful migration) or v0 (rolled back)
			assert_true ("version_check", l_runner.current_version <= 1)

			-- Don't close - database may be locked after error, let GC handle it
		end

	test_migration_version_skip
			-- Test jumping from v1 to v5 (skipping intermediate versions)
		note
			testing: "covers/{SIMPLE_SQL_MIGRATION_RUNNER}.migrate_to"
			testing: "edge_case"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_runner: SIMPLE_SQL_MIGRATION_RUNNER
		do
			create l_db.make_memory

			create l_runner.make (l_db)
			l_runner.add (create {TEST_MIGRATION_001})
			l_runner.add (create {TEST_MIGRATION_002})
			l_runner.add (create {TEST_MIGRATION_003})

			-- First migrate to v1
			assert_true ("migrate_to_1", l_runner.migrate_to (1))
			assert_equal ("at_v1", 1, l_runner.current_version)

			-- Now skip to v3 (should run v2 and v3)
			assert_true ("migrate_to_3", l_runner.migrate_to (3))
			assert_equal ("at_v3", 3, l_runner.current_version)

			l_db.close
		end

	test_migration_downgrade
			-- Test rollback to earlier version
		note
			testing: "covers/{SIMPLE_SQL_MIGRATION_RUNNER}.migrate_to"
			testing: "edge_case"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_runner: SIMPLE_SQL_MIGRATION_RUNNER
			l_schema: SIMPLE_SQL_SCHEMA
		do
			create l_db.make_memory

			create l_runner.make (l_db)
			l_runner.add (create {TEST_MIGRATION_001})
			l_runner.add (create {TEST_MIGRATION_002})
			l_runner.add (create {TEST_MIGRATION_003})

			-- Migrate to latest (v3)
			assert_true ("migrate_all", l_runner.migrate)
			assert_equal ("at_v3", 3, l_runner.current_version)

			-- Downgrade to v1 (should rollback v3 and v2)
			assert_true ("downgrade_to_1", l_runner.migrate_to (1))
			assert_equal ("back_to_v1", 1, l_runner.current_version)

			-- Verify posts table was dropped (v2 rollback)
			create l_schema.make (l_db)
			assert_false ("posts_dropped", l_schema.table_exists ("posts"))
			assert_true ("users_exists", l_schema.table_exists ("users"))

			l_db.close
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
