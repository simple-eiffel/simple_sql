note
	description: "Tests for SIMPLE_SQL_PRAGMA_CONFIG"
	testing: "type/manual"
	testing: "execution/serial"

class
	TEST_SIMPLE_SQL_PRAGMA_CONFIG

inherit
	TEST_SET_BASE

feature -- Test routines: Creation

	test_make_default
			-- Test default configuration
		local
			l_config: SIMPLE_SQL_PRAGMA_CONFIG
		do
			create l_config.make_default
			assert_equal ("journal_delete", l_config.Journal_delete, l_config.journal_mode)
			assert_equal ("sync_full", l_config.Synchronous_full, l_config.synchronous)
			assert_equal ("cache_size", -2000, l_config.cache_size)
			assert_equal ("busy_timeout", 5000, l_config.busy_timeout)
			assert_true ("foreign_keys_on", l_config.foreign_keys)
			assert_equal ("mmap_disabled", {INTEGER_64} 0, l_config.mmap_size)
		end

	test_make_wal
			-- Test WAL configuration
		local
			l_config: SIMPLE_SQL_PRAGMA_CONFIG
		do
			create l_config.make_wal
			assert_equal ("journal_wal", l_config.Journal_wal, l_config.journal_mode)
			assert_equal ("sync_normal", l_config.Synchronous_normal, l_config.synchronous)
			assert_equal ("cache_size", -64000, l_config.cache_size)
			assert_equal ("busy_timeout", 30000, l_config.busy_timeout)
			assert_true ("foreign_keys_on", l_config.foreign_keys)
			assert_equal ("mmap_256mb", {INTEGER_64} 268435456, l_config.mmap_size)
		end

	test_make_performance
			-- Test performance configuration
		local
			l_config: SIMPLE_SQL_PRAGMA_CONFIG
		do
			create l_config.make_performance
			assert_equal ("journal_wal", l_config.Journal_wal, l_config.journal_mode)
			assert_equal ("sync_off", l_config.Synchronous_off, l_config.synchronous)
			assert_equal ("cache_size", -128000, l_config.cache_size)
			assert_equal ("busy_timeout", 60000, l_config.busy_timeout)
			assert_equal ("mmap_512mb", {INTEGER_64} 536870912, l_config.mmap_size)
		end

	test_make_safe
			-- Test safe configuration
		local
			l_config: SIMPLE_SQL_PRAGMA_CONFIG
		do
			create l_config.make_safe
			assert_equal ("journal_wal", l_config.Journal_wal, l_config.journal_mode)
			assert_equal ("sync_extra", l_config.Synchronous_extra, l_config.synchronous)
			assert_equal ("cache_size", -16000, l_config.cache_size)
			assert_equal ("mmap_disabled", {INTEGER_64} 0, l_config.mmap_size)
		end

	test_make_custom
			-- Test custom configuration starts with defaults
		local
			l_config: SIMPLE_SQL_PRAGMA_CONFIG
		do
			create l_config.make_custom
			assert_equal ("journal_delete", l_config.Journal_delete, l_config.journal_mode)
			assert_equal ("sync_full", l_config.Synchronous_full, l_config.synchronous)
		end

feature -- Test routines: Setters

	test_set_journal_mode
			-- Test setting journal mode
		local
			l_config: SIMPLE_SQL_PRAGMA_CONFIG
		do
			create l_config.make_custom
			l_config.set_journal_mode (l_config.Journal_wal)
			assert_equal ("journal_wal", l_config.Journal_wal, l_config.journal_mode)

			l_config.set_journal_mode (l_config.Journal_memory)
			assert_equal ("journal_memory", l_config.Journal_memory, l_config.journal_mode)
		end

	test_set_synchronous
			-- Test setting synchronous level
		local
			l_config: SIMPLE_SQL_PRAGMA_CONFIG
		do
			create l_config.make_custom
			l_config.set_synchronous (l_config.Synchronous_off)
			assert_equal ("sync_off", l_config.Synchronous_off, l_config.synchronous)

			l_config.set_synchronous (l_config.Synchronous_normal)
			assert_equal ("sync_normal", l_config.Synchronous_normal, l_config.synchronous)
		end

	test_set_cache_size
			-- Test setting cache size
		local
			l_config: SIMPLE_SQL_PRAGMA_CONFIG
		do
			create l_config.make_custom
			l_config.set_cache_size (-50000)
			assert_equal ("cache_50mb", -50000, l_config.cache_size)

			l_config.set_cache_size (1000)
			assert_equal ("cache_1000_pages", 1000, l_config.cache_size)
		end

	test_set_busy_timeout
			-- Test setting busy timeout
		local
			l_config: SIMPLE_SQL_PRAGMA_CONFIG
		do
			create l_config.make_custom
			l_config.set_busy_timeout (15000)
			assert_equal ("timeout_15s", 15000, l_config.busy_timeout)
		end

	test_set_foreign_keys
			-- Test setting foreign keys
		local
			l_config: SIMPLE_SQL_PRAGMA_CONFIG
		do
			create l_config.make_custom
			l_config.set_foreign_keys (False)
			assert_false ("fk_off", l_config.foreign_keys)

			l_config.set_foreign_keys (True)
			assert_true ("fk_on", l_config.foreign_keys)
		end

	test_set_mmap_size
			-- Test setting mmap size
		local
			l_config: SIMPLE_SQL_PRAGMA_CONFIG
		do
			create l_config.make_custom
			l_config.set_mmap_size ({INTEGER_64} 134217728)
			assert_equal ("mmap_128mb", {INTEGER_64} 134217728, l_config.mmap_size)
		end

feature -- Test routines: String conversion

	test_journal_mode_string
			-- Test journal mode string conversion
		local
			l_config: SIMPLE_SQL_PRAGMA_CONFIG
		do
			create l_config.make_custom

			l_config.set_journal_mode (l_config.Journal_delete)
			assert_strings_equal ("delete", "DELETE", l_config.journal_mode_string)

			l_config.set_journal_mode (l_config.Journal_wal)
			assert_strings_equal ("wal", "WAL", l_config.journal_mode_string)

			l_config.set_journal_mode (l_config.Journal_memory)
			assert_strings_equal ("memory", "MEMORY", l_config.journal_mode_string)

			l_config.set_journal_mode (l_config.Journal_off)
			assert_strings_equal ("off", "OFF", l_config.journal_mode_string)
		end

	test_synchronous_string
			-- Test synchronous string conversion
		local
			l_config: SIMPLE_SQL_PRAGMA_CONFIG
		do
			create l_config.make_custom

			l_config.set_synchronous (l_config.Synchronous_off)
			assert_strings_equal ("off", "OFF", l_config.synchronous_string)

			l_config.set_synchronous (l_config.Synchronous_normal)
			assert_strings_equal ("normal", "NORMAL", l_config.synchronous_string)

			l_config.set_synchronous (l_config.Synchronous_full)
			assert_strings_equal ("full", "FULL", l_config.synchronous_string)

			l_config.set_synchronous (l_config.Synchronous_extra)
			assert_strings_equal ("extra", "EXTRA", l_config.synchronous_string)
		end

feature -- Test routines: Apply

	test_apply_to_database
			-- Test applying configuration to database
		local
			l_config: SIMPLE_SQL_PRAGMA_CONFIG
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			create l_config.make_wal

			l_config.apply (l_db)

			-- Verify some pragmas were applied
			l_result := l_db.query ("PRAGMA foreign_keys")
			assert_equal ("fk_enabled", 1, l_result.first.integer_value ("foreign_keys"))

			l_result := l_db.query ("PRAGMA busy_timeout")
			assert_equal ("timeout", 30000, l_result.first.integer_value ("timeout"))

			l_db.close
		end

	test_apply_custom_config
			-- Test applying custom configuration
		local
			l_config: SIMPLE_SQL_PRAGMA_CONFIG
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			create l_config.make_custom
			l_config.set_foreign_keys (False)
			l_config.set_busy_timeout (1000)

			l_config.apply (l_db)

			l_result := l_db.query ("PRAGMA foreign_keys")
			assert_equal ("fk_disabled", 0, l_result.first.integer_value ("foreign_keys"))

			l_result := l_db.query ("PRAGMA busy_timeout")
			assert_equal ("timeout_1s", 1000, l_result.first.integer_value ("timeout"))

			l_db.close
		end

feature -- Test routines: Constants

	test_journal_mode_constants
			-- Test journal mode constant values
		local
			l_config: SIMPLE_SQL_PRAGMA_CONFIG
		do
			create l_config.make_custom
			assert_equal ("delete", 0, l_config.Journal_delete)
			assert_equal ("truncate", 1, l_config.Journal_truncate)
			assert_equal ("persist", 2, l_config.Journal_persist)
			assert_equal ("memory", 3, l_config.Journal_memory)
			assert_equal ("wal", 4, l_config.Journal_wal)
			assert_equal ("off", 5, l_config.Journal_off)
		end

	test_synchronous_constants
			-- Test synchronous constant values
		local
			l_config: SIMPLE_SQL_PRAGMA_CONFIG
		do
			create l_config.make_custom
			assert_equal ("off", 0, l_config.Synchronous_off)
			assert_equal ("normal", 1, l_config.Synchronous_normal)
			assert_equal ("full", 2, l_config.Synchronous_full)
			assert_equal ("extra", 3, l_config.Synchronous_extra)
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
