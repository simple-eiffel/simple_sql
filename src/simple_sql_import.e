note
	description: "[
		Import data into database from CSV and JSON formats.

		Usage:
			import := create {SIMPLE_SQL_IMPORT}.make (db)

			-- Import CSV
			import.csv_to_table ("data.csv", "users")
			import.csv_string_to_table (csv_content, "users")

			-- Import JSON (array of objects)
			import.json_to_table ("data.json", "users")
			import.json_string_to_table (json_content, "users")

			-- Import SQL dump
			import.sql_file ("dump.sql")
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_IMPORT

create
	make

feature {NONE} -- Initialization

	make (a_database: SIMPLE_SQL_DATABASE)
			-- Create import helper for `a_database`
		require
			database_attached: a_database /= Void
			database_open: a_database.is_open
		do
			database := a_database
			csv_delimiter := ','
			csv_quote_char := '"'
			csv_has_headers := True
			rows_imported := 0
		ensure
			database_set: database = a_database
		end

feature -- Access

	database: SIMPLE_SQL_DATABASE
			-- Database to import into

	rows_imported: INTEGER
			-- Number of rows imported in last operation

	last_error: detachable STRING_32
			-- Error message from last failed operation

feature -- Status

	had_error: BOOLEAN
			-- Did the last operation fail?
		do
			Result := last_error /= Void
		end

feature -- Configuration

	csv_delimiter: CHARACTER
			-- Delimiter for CSV parsing (default: comma)

	csv_quote_char: CHARACTER
			-- Quote character for CSV parsing (default: double quote)

	csv_has_headers: BOOLEAN
			-- Does CSV file have header row? (default: True)

	set_csv_delimiter (a_char: CHARACTER)
			-- Set CSV delimiter character
		do
			csv_delimiter := a_char
		ensure
			delimiter_set: csv_delimiter = a_char
		end

	set_csv_quote_char (a_char: CHARACTER)
			-- Set CSV quote character
		do
			csv_quote_char := a_char
		ensure
			quote_char_set: csv_quote_char = a_char
		end

	set_csv_has_headers (a_value: BOOLEAN)
			-- Set whether CSV has header row
		do
			csv_has_headers := a_value
		ensure
			has_headers_set: csv_has_headers = a_value
		end

feature -- CSV Import

	csv_to_table (a_file_path: READABLE_STRING_GENERAL; a_table_name: READABLE_STRING_GENERAL)
			-- Import CSV file into existing table
		require
			file_path_not_empty: not a_file_path.is_empty
			table_name_not_empty: not a_table_name.is_empty
			file_exists: (create {RAW_FILE}.make_with_name (a_file_path)).exists
		local
			l_file: PLAIN_TEXT_FILE
			l_content: STRING_32
		do
			create l_file.make_open_read (a_file_path.to_string_32)
			create l_content.make (l_file.count)
			from
				l_file.read_line
			until
				l_file.exhausted
			loop
				l_content.append (l_file.last_string)
				l_content.append ("%N")
				l_file.read_line
			end
			l_file.close

			csv_string_to_table (l_content, a_table_name)
		end

	csv_string_to_table (a_csv: READABLE_STRING_GENERAL; a_table_name: READABLE_STRING_GENERAL)
			-- Import CSV string into existing table
		require
			csv_not_empty: not a_csv.is_empty
			table_name_not_empty: not a_table_name.is_empty
		local
			l_lines: LIST [STRING_32]
			l_headers: detachable ARRAYED_LIST [STRING_32]
			l_values: ARRAYED_LIST [STRING_32]
			l_line_num: INTEGER
			l_sql: STRING_32
		do
			last_error := Void
			rows_imported := 0

			l_lines := a_csv.to_string_32.split ('%N')

			database.begin_transaction

			across l_lines as ic loop
				l_line_num := l_line_num + 1
				if not ic.is_empty and not ic.is_whitespace then
					l_values := parse_csv_line (ic)

					if l_line_num = 1 and csv_has_headers then
						-- First line is headers
						l_headers := l_values
					else
						-- Data row
						l_sql := build_insert_sql (a_table_name, l_headers, l_values)
						database.execute (l_sql.to_string_8)
						if database.has_error then
							last_error := database.last_error_message
							database.rollback
							rows_imported := 0
						else
							rows_imported := rows_imported + 1
						end
					end
				end
			end

			if not had_error then
				database.commit
			end
		rescue
			database.rollback
			rows_imported := 0
			if attached (create {EXCEPTION_MANAGER}).last_exception as l_ex and then attached l_ex.description as al_l_desc then
				create last_error.make_from_string (al_l_desc.to_string_32)
			else
				create last_error.make_from_string ("Unknown error during CSV import")
			end
		end

feature -- JSON Import

	json_to_table (a_file_path: READABLE_STRING_GENERAL; a_table_name: READABLE_STRING_GENERAL)
			-- Import JSON file (array of objects) into existing table
		require
			file_path_not_empty: not a_file_path.is_empty
			table_name_not_empty: not a_table_name.is_empty
			file_exists: (create {RAW_FILE}.make_with_name (a_file_path)).exists
		local
			l_file: PLAIN_TEXT_FILE
			l_content: STRING_32
		do
			create l_file.make_open_read (a_file_path.to_string_32)
			create l_content.make (l_file.count)
			from
				l_file.read_line
			until
				l_file.exhausted
			loop
				l_content.append (l_file.last_string)
				l_content.append ("%N")
				l_file.read_line
			end
			l_file.close

			json_string_to_table (l_content, a_table_name)
		end

	json_string_to_table (a_json: READABLE_STRING_GENERAL; a_table_name: READABLE_STRING_GENERAL)
			-- Import JSON string (array of objects) into existing table
			-- Uses SQLite's JSON functions for parsing
		require
			json_not_empty: not a_json.is_empty
			table_name_not_empty: not a_table_name.is_empty
		local
			l_schema: SIMPLE_SQL_SCHEMA
			l_columns: ARRAYED_LIST [STRING_32]
			l_table_info: detachable SIMPLE_SQL_TABLE_INFO
			l_column_list: STRING_32
			l_select_list: STRING_32
			l_sql: STRING_32
			l_escaped_json: STRING_8
			l_first: BOOLEAN
		do
			last_error := Void
			rows_imported := 0

			-- Get table columns
			l_schema := database.schema
			l_table_info := l_schema.table_info (a_table_name.to_string_8)

			if l_table_info = Void then
				create last_error.make_from_string ("Table not found: " + a_table_name.to_string_32)
			else
				create l_columns.make (l_table_info.columns.count)
				across l_table_info.columns as ic loop
					l_columns.extend (ic.name.to_string_32)
				end

				-- Build column list and JSON extraction expressions
				create l_column_list.make (100)
				create l_select_list.make (200)
				l_first := True

				across l_columns as ic loop
					if not l_first then
						l_column_list.append (", ")
						l_select_list.append (", ")
					end
					l_first := False
					l_column_list.append (ic)
					l_select_list.append ("json_extract(value, '$.")
					l_select_list.append (ic)
					l_select_list.append ("')")
				end

				-- Build INSERT ... SELECT using json_each
				l_escaped_json := escape_sql_string (a_json.to_string_8)

				create l_sql.make (500)
				l_sql.append ("INSERT INTO ")
				l_sql.append (a_table_name.to_string_32)
				l_sql.append (" (")
				l_sql.append (l_column_list)
				l_sql.append (") SELECT ")
				l_sql.append (l_select_list)
				l_sql.append (" FROM json_each('")
				l_sql.append (l_escaped_json.to_string_32)
				l_sql.append ("')")

				database.execute (l_sql.to_string_8)

				if database.has_error then
					last_error := database.last_error_message
				else
					rows_imported := database.changes_count
				end
			end
		end

feature -- SQL Import

	sql_file (a_file_path: READABLE_STRING_GENERAL)
			-- Execute SQL file (for restoring from dump)
		require
			file_path_not_empty: not a_file_path.is_empty
			file_exists: (create {RAW_FILE}.make_with_name (a_file_path)).exists
		local
			l_file: PLAIN_TEXT_FILE
			l_content: STRING_8
			l_size: INTEGER
		do
			create l_file.make_open_read (a_file_path.to_string_32)
			l_size := l_file.count
			create l_content.make (l_size)
			l_file.read_stream (l_size)
			l_content.append (l_file.last_string)
			l_file.close

			sql_string (l_content)
		end

	sql_string (a_sql: READABLE_STRING_8)
			-- Execute SQL statements (for restoring from dump)
		require
			sql_not_empty: not a_sql.is_empty
		local
			l_lines: LIST [READABLE_STRING_8]
			l_line, l_stmt: STRING_8
			l_sql: STRING_8
		do
			last_error := Void
			rows_imported := 0

			-- Process line by line, building up statements
			create l_sql.make_from_string (a_sql)
			l_lines := l_sql.split ('%N')
			create l_stmt.make_empty

			across l_lines as ic loop
				create l_line.make_from_string (ic)
				l_line.left_adjust
				l_line.right_adjust

				-- Skip empty lines and comments
				if not l_line.is_empty and not l_line.starts_with ("--") then
					l_stmt.append (l_line)
					l_stmt.append_character (' ')

					-- Execute when we hit a semicolon
					if l_line.ends_with (";") then
						l_stmt.remove_tail (2) -- Remove trailing "; "
						l_stmt.left_adjust
						l_stmt.right_adjust
						if not l_stmt.is_empty then
							database.execute (l_stmt)
							if database.has_error then
								last_error := database.last_error_message
							else
								rows_imported := rows_imported + database.changes_count
							end
						end
						create l_stmt.make_empty
					end
				end
			end
		end

feature {NONE} -- CSV Parsing

	parse_csv_line (a_line: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- Parse a CSV line into list of values
		local
			l_current: STRING_32
			l_in_quotes: BOOLEAN
			i: INTEGER
			c: CHARACTER_32
		do
			create Result.make (10)
			create l_current.make (50)

			from i := 1 until i > a_line.count loop
				c := a_line.item (i)

				if c = csv_quote_char then
					if l_in_quotes and i + 1 <= a_line.count and a_line.item (i + 1) = csv_quote_char then
						-- Escaped quote
						l_current.append_character (csv_quote_char)
						i := i + 1
					else
						l_in_quotes := not l_in_quotes
					end
				elseif c = csv_delimiter and not l_in_quotes then
					Result.extend (l_current)
					create l_current.make (50)
				elseif c /= '%R' then
					l_current.append_character (c)
				end

				i := i + 1
			end

			-- Add last field
			Result.extend (l_current)
		end

	build_insert_sql (a_table: READABLE_STRING_GENERAL; a_headers: detachable ARRAYED_LIST [STRING_32]; a_values: ARRAYED_LIST [STRING_32]): STRING_32
			-- Build INSERT statement from values
			-- Detects "blob:HEXDATA" values and converts to X'HEXDATA' syntax
		local
			l_first: BOOLEAN
			l_value: STRING_32
		do
			create Result.make (200)
			Result.append ("INSERT INTO ")
			Result.append (a_table.to_string_32)

			if attached a_headers as al_l_hdrs then
				Result.append (" (")
				l_first := True
				across l_hdrs as ic loop
					if not l_first then
						Result.append (", ")
					end
					l_first := False
					Result.append (ic)
				end
				Result.append (")")
			end

			Result.append (" VALUES (")
			l_first := True
			across a_values as ic loop
				if not l_first then
					Result.append (", ")
				end
				l_first := False
				l_value := ic
				if l_value.starts_with ("blob:") then
					-- BLOB encoded value: convert to SQLite hex literal
					Result.append ("X'")
					Result.append (l_value.substring (6, l_value.count))
					Result.append_character ('%'')
				else
					-- Regular string value
					Result.append_character ('%'')
					Result.append (escape_sql_string (l_value.to_string_8).to_string_32)
					Result.append_character ('%'')
				end
			end
			Result.append (")")
		end

feature {NONE} -- SQL Escaping

	escape_sql_string (a_value: READABLE_STRING_8): STRING_8
			-- Escape string for SQL (double single quotes)
		local
			i: INTEGER
			c: CHARACTER
		do
			create Result.make (a_value.count)
			from i := 1 until i > a_value.count loop
				c := a_value.item (i)
				if c = '%'' then
					Result.append_character ('%'')
					Result.append_character ('%'')
				else
					Result.append_character (c)
				end
				i := i + 1
			end
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_SQL - High-level SQLite API for Eiffel
	]"

end
