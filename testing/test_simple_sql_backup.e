note
	description: "Test backup operations between memory and filesystem"
	testing: "type/manual"
	testing: "execution/serial"

class
	TEST_SIMPLE_SQL_BACKUP

inherit
	TEST_SET_BASE
		redefine
			on_prepare,
			on_clean
		end

feature {NONE} -- Events

	on_prepare
			-- Setup before each test
		local
			l_file: RAW_FILE
		do
			Precursor
			create backup_helper
			
			-- Clean up any leftover test files
			create l_file.make_with_name (Test_db_file)
			if l_file.exists then
				l_file.delete
			end
			create l_file.make_with_name (Test_db_file_2)
			if l_file.exists then
				l_file.delete
			end
		end

	on_clean
			-- Cleanup after each test
		local
			l_file: RAW_FILE
		do
			-- Remove test database files
			create l_file.make_with_name (Test_db_file)
			if l_file.exists then
				l_file.delete
			end
			create l_file.make_with_name (Test_db_file_2)
			if l_file.exists then
				l_file.delete
			end
			Precursor
		end

feature -- Test routines

	test_backup_memory_to_file
			-- Test backing up in-memory database to file
		note
			testing: "covers/{SIMPLE_SQL_BACKUP}.copy_memory_to_file"
		local
			l_mem_db: SIMPLE_SQL_DATABASE
			l_file_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			-- Create and populate memory database
			create l_mem_db.make_memory
			l_mem_db.execute ("CREATE TABLE users (id INTEGER, name TEXT)")
			l_mem_db.execute ("INSERT INTO users VALUES (1, 'Alice')")
			l_mem_db.execute ("INSERT INTO users VALUES (2, 'Bob')")
			
			-- Backup to file
			backup_helper.copy_memory_to_file (l_mem_db, Test_db_file)
			l_mem_db.close
			
			-- Verify file database
			create l_file_db.make_read_only (Test_db_file)
			l_result := l_file_db.query ("SELECT COUNT(*) as cnt FROM users")
			assert_equal ("count_two", 2, l_result.first.integer_value ("cnt"))
			
			l_result := l_file_db.query ("SELECT name FROM users ORDER BY id")
			assert_strings_equal ("first_name", "Alice", l_result.first.string_value ("name"))
			l_file_db.close
		end

	test_backup_file_to_memory
			-- Test restoring file database to memory
		note
			testing: "covers/{SIMPLE_SQL_BACKUP}.copy_file_to_memory"
		local
			l_file_db: SIMPLE_SQL_DATABASE
			l_mem_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			-- Create file database
			create l_file_db.make (Test_db_file)
			l_file_db.execute ("CREATE TABLE products (id INTEGER, name TEXT, price REAL)")
			l_file_db.execute ("INSERT INTO products VALUES (1, 'Widget', 9.99)")
			l_file_db.execute ("INSERT INTO products VALUES (2, 'Gadget', 19.99)")
			l_file_db.close
			
			-- Restore to memory
			create l_mem_db.make_memory
			backup_helper.copy_file_to_memory (Test_db_file, l_mem_db)
			
			-- Verify memory database
			l_result := l_mem_db.query ("SELECT COUNT(*) as cnt FROM products")
			assert_equal ("count_two", 2, l_result.first.integer_value ("cnt"))
			
			l_result := l_mem_db.query ("SELECT price FROM products WHERE name = 'Widget'")
			assert_reals_equal ("widget_price", 9.99, l_result.first.real_value ("price"), 0.01)
			
			l_mem_db.close
		end

	test_round_trip_backup
			-- Test memory -> file -> memory round trip
		note
			testing: "covers/{SIMPLE_SQL_BACKUP}.copy_memory_to_file"
			testing: "covers/{SIMPLE_SQL_BACKUP}.copy_file_to_memory"
		local
			l_mem1, l_mem2: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			-- Create original memory database
			create l_mem1.make_memory
			l_mem1.execute ("CREATE TABLE data (value TEXT)")
			l_mem1.execute ("INSERT INTO data VALUES ('original')")
			
			-- Backup to file
			backup_helper.copy_memory_to_file (l_mem1, Test_db_file)
			l_mem1.close
			
			-- Restore to new memory database
			create l_mem2.make_memory
			backup_helper.copy_file_to_memory (Test_db_file, l_mem2)
			
			-- Verify data survived round trip
			l_result := l_mem2.query ("SELECT value FROM data")
			assert_strings_equal ("round_trip", "original", l_result.first.string_value ("value"))
			
			l_mem2.close
		end

	test_backup_with_null_values
			-- Test backup preserves NULL values
		note
			testing: "covers/{SIMPLE_SQL_BACKUP}.copy_memory_to_file"
		local
			l_mem_db: SIMPLE_SQL_DATABASE
			l_file_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			-- Create database with NULLs
			create l_mem_db.make_memory
			l_mem_db.execute ("CREATE TABLE test (id INTEGER, name TEXT, age INTEGER)")
			l_mem_db.execute ("INSERT INTO test (id, name) VALUES (1, 'Alice')")
			
			-- Backup
			backup_helper.copy_memory_to_file (l_mem_db, Test_db_file)
			l_mem_db.close
			
			-- Verify NULL preserved
			create l_file_db.make_read_only (Test_db_file)
			l_result := l_file_db.query ("SELECT * FROM test")
			assert_true ("age_is_null", l_result.first.is_null ("age"))
			l_file_db.close
		end

	test_backup_with_special_characters
			-- Test backup handles quotes and special chars
		note
			testing: "covers/{SIMPLE_SQL_BACKUP}.copy_memory_to_file"
		local
			l_mem_db: SIMPLE_SQL_DATABASE
			l_file_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
			l_test_string: STRING_8
		do
			create l_test_string.make_from_string ("O''Brien''s ''test'' data")
			
			-- Create database with special characters
			create l_mem_db.make_memory
			l_mem_db.execute ("CREATE TABLE test (text TEXT)")
			l_mem_db.execute ("INSERT INTO test VALUES ('" + l_test_string + "')")
			
			-- Backup
			backup_helper.copy_memory_to_file (l_mem_db, Test_db_file)
			l_mem_db.close
			
			-- Verify special chars preserved
			create l_file_db.make_read_only (Test_db_file)
			l_result := l_file_db.query ("SELECT * FROM test")
			assert_string_contains ("has_obrien", l_result.first.string_value ("text"), "O'Brien")
			l_file_db.close
		end

feature {NONE} -- Implementation

	backup_helper: SIMPLE_SQL_BACKUP
			-- Backup helper instance

feature {NONE} -- Constants

	Test_db_file: STRING_8 = "test_backup.db"
			-- Test database file name

	Test_db_file_2: STRING_8 = "test_backup_2.db"
			-- Second test database file name

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_SQL - High-level SQLite API for Eiffel
	]"

end
