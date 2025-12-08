note
	description: "Test suite for BLOB handling in SIMPLE_SQL"
	testing: "covers"
	testing: "execution/serial"

class
	TEST_SIMPLE_SQL_BLOB

inherit
	TEST_SET_BASE

feature -- Test routines

	test_blob_insert_and_retrieve
			-- Test basic BLOB insert and retrieve operations
		note
			testing: "covers/{SIMPLE_SQL_PREPARED_STATEMENT}.bind_blob"
			testing: "covers/{SIMPLE_SQL_ROW}.blob_value"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
			l_result: SIMPLE_SQL_RESULT
			l_blob_in: MANAGED_POINTER
			l_blob_out: detachable MANAGED_POINTER
			i: INTEGER
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE test_blobs (id INTEGER PRIMARY KEY, data BLOB)")

			-- Create test BLOB data (100 bytes)
			create l_blob_in.make (100)
			from i := 0 until i >= 100 loop
				l_blob_in.put_natural_8 (i.to_natural_8, i)
				i := i + 1
			end

			-- Insert BLOB using prepared statement
			l_stmt := l_db.prepare ("INSERT INTO test_blobs (id, data) VALUES (?, ?)")
			l_stmt.bind_integer (1, 1)
			l_stmt.bind_blob (2, l_blob_in)
			l_stmt.execute

			refute ("no_error_on_insert", l_db.has_error)

			-- Retrieve BLOB
			l_result := l_db.query ("SELECT data FROM test_blobs WHERE id = 1")
			assert_false ("result_not_empty", l_result.is_empty)

			l_blob_out := l_result.first.blob_value ("data")
			assert_true ("blob_retrieved", l_blob_out /= Void)

			if attached l_blob_out as l_blob then
				assert_equal ("blob_size", 100, l_blob.count)
				-- Verify first and last bytes
				assert_equal ("first_byte", 0, l_blob.read_natural_8 (0).to_integer_32)
				assert_equal ("last_byte", 99, l_blob.read_natural_8 (99).to_integer_32)
			end

			l_db.close
		end

	test_blob_bind_by_name
			-- Test BLOB binding using named parameters
		note
			testing: "covers/{SIMPLE_SQL_PREPARED_STATEMENT}.bind_blob_by_name"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
			l_result: SIMPLE_SQL_RESULT
			l_blob: MANAGED_POINTER
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE documents (name TEXT, content BLOB)")

			-- Create test BLOB
			create l_blob.make (50)
			l_blob.put_natural_8 (255, 0)
			l_blob.put_natural_8 (128, 49)

			-- Insert using named parameter
			l_stmt := l_db.prepare ("INSERT INTO documents (name, content) VALUES (:name, :content)")
			l_stmt.bind_text_by_name (":name", "test.bin")
			l_stmt.bind_blob_by_name (":content", l_blob)
			l_stmt.execute

			refute ("no_error_on_insert", l_db.has_error)

			-- Verify
			l_result := l_db.query ("SELECT content FROM documents WHERE name = 'test.bin'")
			refute ("no_error_on_query", l_db.has_error)
			assert_false ("result_not_empty", l_result.is_empty)

			if attached l_result.first.blob_value ("content") as l_retrieved then
				assert_equal ("size_matches", 50, l_retrieved.count)
				assert_equal ("first_byte_matches", 255, l_retrieved.read_natural_8 (0).to_integer_32)
				assert_equal ("last_byte_matches", 128, l_retrieved.read_natural_8 (49).to_integer_32)
			else
				assert_true ("blob_should_exist", False)
			end

			l_db.close
		end

	test_blob_null_handling
			-- Test NULL BLOB handling
		note
			testing: "covers/{SIMPLE_SQL_ROW}.blob_value"
			testing: "covers/{SIMPLE_SQL_ROW}.is_null"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE nullable_blobs (id INTEGER, data BLOB)")
			l_db.execute ("INSERT INTO nullable_blobs (id, data) VALUES (1, NULL)")

			l_result := l_db.query ("SELECT data FROM nullable_blobs WHERE id = 1")
			assert_false ("result_not_empty", l_result.is_empty)
			assert_true ("blob_is_null", l_result.first.is_null ("data"))
			assert_true ("blob_value_is_void", l_result.first.blob_value ("data") = Void)

			l_db.close
		end

	test_blob_from_file
			-- Test reading BLOB from file and storing in database
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.read_blob_from_file"
			testing: "covers/{SIMPLE_SQL_PREPARED_STATEMENT}.bind_blob"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_file: RAW_FILE
			l_file_path: STRING_32
			l_blob: detachable MANAGED_POINTER
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
			l_result: SIMPLE_SQL_RESULT
			i: INTEGER
		do
			create l_db.make_memory

			-- Create temporary test file
			l_file_path := "test_blob_temp.bin"
			create l_file.make_create_read_write (l_file_path)
			from i := 0 until i >= 256 loop
				l_file.put_character (i.to_character_8)
				i := i + 1
			end
			l_file.close

			-- Read BLOB from file
			l_blob := l_db.read_blob_from_file (l_file_path)
			assert_true ("blob_read", l_blob /= Void)

			if attached l_blob as l_data then
				assert_equal ("blob_size", 256, l_data.count)

				-- Store in database
				l_db.execute ("CREATE TABLE files (name TEXT, data BLOB)")
				l_stmt := l_db.prepare ("INSERT INTO files (name, data) VALUES (?, ?)")
				l_stmt.bind_text (1, "test_file")
				l_stmt.bind_blob (2, l_data)
				l_stmt.execute

				-- Verify
				l_result := l_db.query ("SELECT data FROM files WHERE name = 'test_file'")
				if attached l_result.first.blob_value ("data") as l_retrieved then
					assert_equal ("retrieved_size", 256, l_retrieved.count)
					assert_equal ("first_byte", 0, l_retrieved.read_natural_8 (0).to_integer_32)
					assert_equal ("last_byte", 255, l_retrieved.read_natural_8 (255).to_integer_32)
				else
					assert_true ("should_have_blob", False)
				end
			end

			-- Cleanup
			l_db.close
			create l_file.make_with_name (l_file_path)
			if l_file.exists then
				l_file.delete
			end
		end

	test_blob_to_file
			-- Test writing BLOB from database to file
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.write_blob_to_file"
			testing: "covers/{SIMPLE_SQL_ROW}.blob_value"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
			l_result: SIMPLE_SQL_RESULT
			l_blob: MANAGED_POINTER
			l_file: RAW_FILE
			l_file_path: STRING_32
			i: INTEGER
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE images (id INTEGER, data BLOB)")

			-- Create test BLOB
			create l_blob.make (128)
			from i := 0 until i >= 128 loop
				l_blob.put_natural_8 ((i * 2).to_natural_8, i)
				i := i + 1
			end

			-- Store in database
			l_stmt := l_db.prepare ("INSERT INTO images (id, data) VALUES (?, ?)")
			l_stmt.bind_integer (1, 1)
			l_stmt.bind_blob (2, l_blob)
			l_stmt.execute

			-- Retrieve and write to file
			l_result := l_db.query ("SELECT data FROM images WHERE id = 1")
			if attached l_result.first.blob_value ("data") as l_retrieved then
				l_file_path := "test_blob_output.bin"
				l_db.write_blob_to_file (l_retrieved, l_file_path)

				-- Verify file was created and has correct content
				create l_file.make_with_name (l_file_path)
				assert_true ("file_exists", l_file.exists)
				assert_equal ("file_size", 128, l_file.count)

				-- Read and verify content
				l_file.open_read
				l_file.read_character
				assert_equal ("first_byte_in_file", 0, l_file.last_character.code)
				l_file.read_stream (126)  -- Skip to near end
				l_file.read_character
				assert_equal ("last_byte_in_file", 254, l_file.last_character.code)
				l_file.close

				-- Cleanup
				l_file.delete
			else
				assert_true ("should_have_blob", False)
			end

			l_db.close
		end

	test_blob_large_data
			-- Test handling of larger BLOBs (1MB)
		note
			testing: "covers/{SIMPLE_SQL_PREPARED_STATEMENT}.bind_blob"
			testing: "covers/{SIMPLE_SQL_ROW}.blob_value"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
			l_result: SIMPLE_SQL_RESULT
			l_blob: MANAGED_POINTER
			l_size: INTEGER
			i: INTEGER
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE large_blobs (id INTEGER, data BLOB)")

			-- Create 1MB BLOB
			l_size := 1048576  -- 1MB
			create l_blob.make (l_size)
			from i := 0 until i >= l_size loop
				l_blob.put_natural_8 ((i \\ 256).to_natural_8, i)
				i := i + 1
			end

			-- Store large BLOB
			l_stmt := l_db.prepare ("INSERT INTO large_blobs (id, data) VALUES (?, ?)")
			l_stmt.bind_integer (1, 1)
			l_stmt.bind_blob (2, l_blob)
			l_stmt.execute

			refute ("no_error_on_large_insert", l_db.has_error)

			-- Retrieve and verify
			l_result := l_db.query ("SELECT data FROM large_blobs WHERE id = 1")
			if attached l_result.first.blob_value ("data") as l_retrieved then
				assert_equal ("large_blob_size", l_size, l_retrieved.count)
				-- Verify some bytes
				assert_equal ("byte_at_0", 0, l_retrieved.read_natural_8 (0).to_integer_32)
				assert_equal ("byte_at_1000", 232, l_retrieved.read_natural_8 (1000).to_integer_32)  -- 1000 % 256 = 232
				assert_equal ("byte_at_end", 255, l_retrieved.read_natural_8 (l_size - 1).to_integer_32)  -- (1048575 % 256) = 255
			else
				assert_true ("should_have_large_blob", False)
			end

			l_db.close
		end

	test_blob_roundtrip_file_to_db_to_file
			-- Test complete roundtrip: file -> database -> file
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.read_blob_from_file"
			testing: "covers/{SIMPLE_SQL_DATABASE}.write_blob_to_file"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
			l_result: SIMPLE_SQL_RESULT
			l_file: RAW_FILE
			l_input_path: STRING_32
			l_output_path: STRING_32
			l_blob: detachable MANAGED_POINTER
			i: INTEGER
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE file_storage (name TEXT, data BLOB)")

			-- Create source file
			l_input_path := "test_input.bin"
			create l_file.make_create_read_write (l_input_path)
			from i := 0 until i >= 512 loop
				l_file.put_character ((i \\ 128).to_character_8)
				i := i + 1
			end
			l_file.close

			-- Read from file, store in DB
			l_blob := l_db.read_blob_from_file (l_input_path)
			if attached l_blob as l_data then
				l_stmt := l_db.prepare ("INSERT INTO file_storage (name, data) VALUES (?, ?)")
				l_stmt.bind_text (1, "roundtrip")
				l_stmt.bind_blob (2, l_data)
				l_stmt.execute

				-- Retrieve from DB, write to file
				l_result := l_db.query ("SELECT data FROM file_storage WHERE name = 'roundtrip'")
				if attached l_result.first.blob_value ("data") as l_retrieved then
					l_output_path := "test_output.bin"
					l_db.write_blob_to_file (l_retrieved, l_output_path)

					-- Verify output file matches input
					create l_file.make_with_name (l_output_path)
					assert_true ("output_file_exists", l_file.exists)
					assert_equal ("output_file_size", 512, l_file.count)

					-- Verify content matches
					l_file.open_read
					l_file.read_character
					assert_equal ("output_first_byte", 0, l_file.last_character.code)
					l_file.read_stream (510)
					l_file.read_character
					assert_equal ("output_last_byte", 127, l_file.last_character.code)  -- (511 % 128) = 127
					l_file.close

					-- Cleanup
					l_file.delete
				else
					assert_true ("should_retrieve_blob", False)
				end
			else
				assert_true ("should_read_file", False)
			end

			-- Cleanup
			l_db.close
			create l_file.make_with_name (l_input_path)
			if l_file.exists then
				l_file.delete
			end
		end

end
