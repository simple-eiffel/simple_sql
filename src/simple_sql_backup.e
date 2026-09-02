note
	description: "[
		A unified backup facade for SQLite databases supporting copy, online backup,
		export, and import operations.
		Provides factory methods for online backup via the SQLite Backup API and
		data exchange in CSV, JSON, and SQL formats.
		Acts as the central backup and data-portability entry point for simple_sql.
	]"
	purpose: "Provide backup, export, and import operations for SQLite databases"
	collaborators: "SIMPLE_SQL_DATABASE, SIMPLE_SQL_ONLINE_BACKUP, SIMPLE_SQL_EXPORT, SIMPLE_SQL_IMPORT, SIMPLE_SQL_RESULT, SIMPLE_SQL_ROW"
	design_pattern: "Facade"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_BACKUP

feature -- Factory Methods

	online_backup (a_source, a_destination: SIMPLE_SQL_DATABASE): SIMPLE_SQL_ONLINE_BACKUP
			-- Create online backup operation from source to destination
		note
			semantic_role: "[
				Creates an online backup operation
				between two open databases via the
				SQLite Backup API.
			]"
		require
			source_attached: a_source /= Void
			source_open: a_source.is_open
			destination_attached: a_destination /= Void
			destination_open: a_destination.is_open
		do
			create Result.make (a_source, a_destination)
		ensure
			result_attached: Result /= Void
		end

	online_backup_to_file (a_source: SIMPLE_SQL_DATABASE; a_destination_path: READABLE_STRING_GENERAL): SIMPLE_SQL_ONLINE_BACKUP
			-- Create online backup from source to new file
		note
			semantic_role: "[
				Creates an online backup from a source
				database to a new file path.
			]"
		require
			source_attached: a_source /= Void
			source_open: a_source.is_open
			path_not_empty: not a_destination_path.is_empty
		do
			create Result.make_to_file (a_source, a_destination_path)
		ensure
			result_attached: Result /= Void
		end

	online_backup_from_file (a_source_path: READABLE_STRING_GENERAL; a_destination: SIMPLE_SQL_DATABASE): SIMPLE_SQL_ONLINE_BACKUP
			-- Create online backup from file to destination
		note
			semantic_role: "[
				Creates an online backup from a file
				into a destination database.
			]"
		require
			path_not_empty: not a_source_path.is_empty
			file_exists: (create {RAW_FILE}.make_with_name (a_source_path)).exists
			destination_attached: a_destination /= Void
			destination_open: a_destination.is_open
		do
			create Result.make_from_file (a_source_path, a_destination)
		ensure
			result_attached: Result /= Void
		end

	exporter (a_database: SIMPLE_SQL_DATABASE): SIMPLE_SQL_EXPORT
			-- Create exporter for CSV, JSON, SQL export
		note
			semantic_role: "[
				Creates an export helper for CSV, JSON,
				and SQL format output from a database.
			]"
		require
			database_attached: a_database /= Void
			database_open: a_database.is_open
		do
			create Result.make (a_database)
		ensure
			result_attached: Result /= Void
		end

	importer (a_database: SIMPLE_SQL_DATABASE): SIMPLE_SQL_IMPORT
			-- Create importer for CSV, JSON, SQL import
		note
			semantic_role: "[
				Creates an import helper for CSV, JSON,
				and SQL format input into a database.
			]"
		require
			database_attached: a_database /= Void
			database_open: a_database.is_open
		do
			create Result.make (a_database)
		ensure
			result_attached: Result /= Void
		end

feature -- Simple Copy Operations

	copy_memory_to_file (a_memory_db: SIMPLE_SQL_DATABASE; a_file_name: READABLE_STRING_GENERAL)
			-- Copy in-memory database to file
		note
			semantic_role: "[
				Copies an in-memory database to a file
				via schema and data replication.
			]"
		require
			memory_db_attached: a_memory_db /= Void
			memory_db_open: a_memory_db.is_open
			file_name_not_empty: not a_file_name.is_empty
		local
			l_file_db: SIMPLE_SQL_DATABASE
			l_schema: SIMPLE_SQL_RESULT
			l_tables: SIMPLE_SQL_RESULT
		do
			create l_file_db.make (a_file_name)

			-- Copy schema
			l_schema := a_memory_db.query ("SELECT sql FROM sqlite_master WHERE type='table' AND sql NOT NULL")
			across l_schema.rows as ic loop
				if attached ic.string_value ("sql") as al_sql then
					l_file_db.execute (al_sql.to_string_8)
				end
			end

			-- Copy data for each table
			l_tables := a_memory_db.query ("SELECT name FROM sqlite_master WHERE type='table'")
			across l_tables.rows as ic loop
				copy_table_data (a_memory_db, l_file_db, ic.string_value ("name"))
			end

			l_file_db.close
		end

	copy_file_to_memory (a_file_name: READABLE_STRING_GENERAL; a_memory_db: SIMPLE_SQL_DATABASE)
			-- Copy file database to in-memory database
		note
			semantic_role: "[
				Copies a file database into memory via
				schema and data replication.
			]"
		require
			memory_db_attached: a_memory_db /= Void
			memory_db_open: a_memory_db.is_open
			file_name_not_empty: not a_file_name.is_empty
			file_exists: (create {RAW_FILE}.make_with_name (a_file_name)).exists
		local
			l_file_db: SIMPLE_SQL_DATABASE
			l_schema: SIMPLE_SQL_RESULT
			l_tables: SIMPLE_SQL_RESULT
		do
			create l_file_db.make_read_only (a_file_name)

			-- Copy schema
			l_schema := l_file_db.query ("SELECT sql FROM sqlite_master WHERE type='table' AND sql NOT NULL")
			across l_schema.rows as ic loop
				if attached ic.string_value ("sql") as al_sql then
					a_memory_db.execute (al_sql.to_string_8)
				end
			end

			-- Copy data for each table
			l_tables := l_file_db.query ("SELECT name FROM sqlite_master WHERE type='table'")
			across l_tables.rows as ic loop
				copy_table_data (l_file_db, a_memory_db, ic.string_value ("name"))
			end

			l_file_db.close
		end

feature {NONE} -- Implementation

	copy_table_data (a_source, a_destination: SIMPLE_SQL_DATABASE; a_table_name: STRING_32)
			-- Copy all data from source table to destination table
			-- Handles BLOB data using SQLite X'HEXDATA' syntax
		note
			semantic_role: "[
				Replicates all rows from a source table
				to a destination with type-aware SQL
				generation including BLOB hex encoding.
			]"
		require
			source_attached: a_source /= Void
			destination_attached: a_destination /= Void
			table_name_not_empty: not a_table_name.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
			l_insert_sql: STRING_32
			l_row: SIMPLE_SQL_ROW
			i: INTEGER
		do
			create l_insert_sql.make_from_string ("SELECT * FROM ")
			l_insert_sql.append (a_table_name)

			l_result := a_source.query (l_insert_sql.to_string_8)

			across l_result.rows as ic_row loop
				l_row := ic_row
				create l_insert_sql.make_from_string ("INSERT INTO ")
				l_insert_sql.append (a_table_name)
				l_insert_sql.append (" VALUES (")

				from
					i := 1
				until
					i > l_row.count
				loop
					if i > 1 then
						l_insert_sql.append (", ")
					end

					if l_row.is_null (l_row.column_name (i)) then
						l_insert_sql.append ("NULL")
					elseif attached {INTEGER_64} l_row [i] as al_int then
						l_insert_sql.append (al_int.out)
					elseif attached {REAL_64} l_row [i] as al_real then
						l_insert_sql.append (al_real.out)
					elseif attached {MANAGED_POINTER} l_row [i] as al_blob then
						-- BLOB: encode using SQLite hex literal X'...'
						l_insert_sql.append ("X'")
						l_insert_sql.append (blob_to_hex (al_blob))
						l_insert_sql.append_character ('%'')
					elseif attached {READABLE_STRING_GENERAL} l_row [i] as al_string then
						l_insert_sql.append_character ('%'')
						l_insert_sql.append (escape_string (al_string))
						l_insert_sql.append_character ('%'')
					else
						l_insert_sql.append ("NULL")
					end

					i := i + 1
				end

				l_insert_sql.append (")")
				a_destination.execute (l_insert_sql.to_string_8)
			end
		end

	escape_string (a_string: READABLE_STRING_GENERAL): STRING_32
			-- Escape single quotes for SQL
		note
			semantic_role: "[
				Doubles single quotes for safe SQL
				string embedding in generated INSERT
				statements.
			]"
		local
			i: INTEGER
			c: CHARACTER_32
		do
			create Result.make (a_string.count)
			from
				i := 1
			until
				i > a_string.count
			loop
				c := a_string.item (i)
				if c = '%'' then
					Result.append_character ('%'')
					Result.append_character ('%'')
				else
					Result.append_character (c)
				end
				i := i + 1
			end
		end

	blob_to_hex (a_blob: MANAGED_POINTER): STRING_32
			-- Convert BLOB to uppercase hexadecimal string
		note
			semantic_role: "[
				Converts a MANAGED_POINTER blob to
				uppercase hexadecimal string for
				SQLite X'...' literal syntax.
			]"
		local
			i: INTEGER
			l_byte: NATURAL_8
		do
			create Result.make (a_blob.count * 2)
			from i := 0 until i >= a_blob.count loop
				l_byte := a_blob.read_natural_8 (i)
				Result.append (byte_to_hex (l_byte))
				i := i + 1
			end
		ensure
			correct_length: Result.count = a_blob.count * 2
		end

	byte_to_hex (a_byte: NATURAL_8): STRING_32
			-- Convert single byte to two hex characters (uppercase)
		note
			semantic_role: "[
				Converts a single byte to a two-char
				uppercase hex representation.
			]"
		local
			l_high, l_low: NATURAL_8
		do
			create Result.make (2)
			l_high := a_byte |>> 4
			l_low := a_byte & 0x0F
			Result.append_character (hex_char (l_high))
			Result.append_character (hex_char (l_low))
		ensure
			two_chars: Result.count = 2
		end

	hex_char (a_nibble: NATURAL_8): CHARACTER_32
			-- Convert nibble (0-15) to hex character
		note
			semantic_role: "[
				Maps a nibble value (0-15) to its
				hexadecimal character (0-9, A-F).
			]"
		require
			valid_nibble: a_nibble <= 15
		local
			l_code: NATURAL_32
		do
			if a_nibble < 10 then
				l_code := ('0').code.to_natural_32 + a_nibble.to_natural_32
			else
				l_code := ('A').code.to_natural_32 + (a_nibble - 10).to_natural_32
			end
			Result := l_code.to_character_32
		ensure
			valid_hex: ("0123456789ABCDEF").has (Result.to_character_8)
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
