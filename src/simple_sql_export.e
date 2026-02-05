note
	description: "[
		Export database tables to various formats: CSV, JSON, and SQL dump.

		Usage:
			export := create {SIMPLE_SQL_EXPORT}.make (db)

			-- Export single table
			export.table_to_csv ("users", "users.csv")
			export.table_to_json ("users", "users.json")
			export.table_to_sql ("users", "users.sql")

			-- Export entire database
			export.database_to_csv ("backup/")
			export.database_to_json ("backup/data.json")
			export.database_to_sql ("backup/dump.sql")

			-- Get as string (for memory export)
			csv_string := export.table_csv_string ("users")
			json_string := export.table_json_string ("users")
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_EXPORT

create
	make

feature {NONE} -- Initialization

	make (a_database: SIMPLE_SQL_DATABASE)
			-- Create export helper for `a_database`
		require
			database_attached: a_database /= Void
			database_open: a_database.is_open
		do
			database := a_database
			csv_delimiter := ','
			csv_quote_char := '"'
			csv_include_headers := True
			json_pretty_print := True
		ensure
			database_set: database = a_database
		end

feature -- Access

	database: SIMPLE_SQL_DATABASE
			-- Database to export from

feature -- Configuration

	csv_delimiter: CHARACTER
			-- Delimiter for CSV export (default: comma)

	csv_quote_char: CHARACTER
			-- Quote character for CSV export (default: double quote)

	csv_include_headers: BOOLEAN
			-- Include column headers in CSV export (default: True)

	json_pretty_print: BOOLEAN
			-- Format JSON with indentation (default: True)

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

	set_csv_include_headers (a_value: BOOLEAN)
			-- Set whether to include headers in CSV
		do
			csv_include_headers := a_value
		ensure
			include_headers_set: csv_include_headers = a_value
		end

	set_json_pretty_print (a_value: BOOLEAN)
			-- Set whether to pretty-print JSON
		do
			json_pretty_print := a_value
		ensure
			pretty_print_set: json_pretty_print = a_value
		end

feature -- CSV Export

	table_to_csv (a_table_name: READABLE_STRING_GENERAL; a_file_path: READABLE_STRING_GENERAL)
			-- Export table to CSV file
		require
			table_name_not_empty: not a_table_name.is_empty
			file_path_not_empty: not a_file_path.is_empty
		local
			l_file: PLAIN_TEXT_FILE
			l_content: STRING_32
		do
			l_content := table_csv_string (a_table_name)
			create l_file.make_create_read_write (a_file_path.to_string_32)
			l_file.put_string (l_content.to_string_8)
			l_file.close
		end

	table_csv_string (a_table_name: READABLE_STRING_GENERAL): STRING_32
			-- Get table contents as CSV string
		require
			table_name_not_empty: not a_table_name.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
			l_row: SIMPLE_SQL_ROW
			i: INTEGER
		do
			create Result.make (1024)

			l_result := database.query ("SELECT * FROM " + a_table_name.to_string_8)

			-- Headers
			if csv_include_headers and not l_result.rows.is_empty then
				l_row := l_result.rows.first
				from i := 1 until i > l_row.count loop
					if i > 1 then
						Result.append_character (csv_delimiter)
					end
					Result.append (escape_csv_value (l_row.column_name (i)))
					i := i + 1
				end
				Result.append ("%N")
			end

			-- Data rows
			across l_result.rows as ic loop
				l_row := ic
				from i := 1 until i > l_row.count loop
					if i > 1 then
						Result.append_character (csv_delimiter)
					end
					Result.append (format_csv_value (l_row, i))
					i := i + 1
				end
				Result.append ("%N")
			end
		end

	database_to_csv (a_directory_path: READABLE_STRING_GENERAL)
			-- Export all tables to CSV files in directory (one file per table)
		require
			directory_path_not_empty: not a_directory_path.is_empty
		local
			l_schema: SIMPLE_SQL_SCHEMA
			l_tables: ARRAYED_LIST [STRING_8]
			l_path: STRING_32
		do
			l_schema := database.schema
			l_tables := l_schema.tables

			across l_tables as ic loop
				create l_path.make_from_string (a_directory_path.to_string_32)
				if not l_path.ends_with_general ("/") and not l_path.ends_with_general ("\") then
					l_path.append_character ('/')
				end
				l_path.append (ic.to_string_32)
				l_path.append (".csv")
				table_to_csv (ic, l_path)
			end
		end

feature -- JSON Export

	table_to_json (a_table_name: READABLE_STRING_GENERAL; a_file_path: READABLE_STRING_GENERAL)
			-- Export table to JSON file (as array of objects)
		require
			table_name_not_empty: not a_table_name.is_empty
			file_path_not_empty: not a_file_path.is_empty
		local
			l_file: PLAIN_TEXT_FILE
			l_content: STRING_32
		do
			l_content := table_json_string (a_table_name)
			create l_file.make_create_read_write (a_file_path.to_string_32)
			l_file.put_string (l_content.to_string_8)
			l_file.close
		end

	table_json_string (a_table_name: READABLE_STRING_GENERAL): STRING_32
			-- Get table contents as JSON array of objects
		require
			table_name_not_empty: not a_table_name.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
			l_row: SIMPLE_SQL_ROW
			i: INTEGER
			l_first_row: BOOLEAN
			l_indent: STRING_32
			l_newline: STRING_32
		do
			create Result.make (1024)

			if json_pretty_print then
				l_indent := "  "
				l_newline := "%N"
			else
				l_indent := ""
				l_newline := ""
			end

			l_result := database.query ("SELECT * FROM " + a_table_name.to_string_8)

			Result.append ("[")
			Result.append (l_newline)

			l_first_row := True
			across l_result.rows as ic loop
				l_row := ic
				if not l_first_row then
					Result.append (",")
					Result.append (l_newline)
				end
				l_first_row := False

				Result.append (l_indent)
				Result.append ("{")
				Result.append (l_newline)

				from i := 1 until i > l_row.count loop
					if i > 1 then
						Result.append (",")
						Result.append (l_newline)
					end
					Result.append (l_indent)
					Result.append (l_indent)
					Result.append ("%"")
					Result.append (escape_json_string (l_row.column_name (i)))
					Result.append ("%": ")
					Result.append (format_json_value (l_row, i))
					i := i + 1
				end

				Result.append (l_newline)
				Result.append (l_indent)
				Result.append ("}")
			end

			Result.append (l_newline)
			Result.append ("]")
		end

	database_to_json (a_file_path: READABLE_STRING_GENERAL)
			-- Export entire database to JSON file (as object with table arrays)
		require
			file_path_not_empty: not a_file_path.is_empty
		local
			l_file: PLAIN_TEXT_FILE
			l_content: STRING_32
		do
			l_content := database_json_string
			create l_file.make_create_read_write (a_file_path.to_string_32)
			l_file.put_string (l_content.to_string_8)
			l_file.close
		end

	database_json_string: STRING_32
			-- Get entire database as JSON object with table arrays
		local
			l_schema: SIMPLE_SQL_SCHEMA
			l_tables: ARRAYED_LIST [STRING_8]
			l_first: BOOLEAN
			l_indent: STRING_32
			l_newline: STRING_32
		do
			create Result.make (4096)

			if json_pretty_print then
				l_indent := "  "
				l_newline := "%N"
			else
				l_indent := ""
				l_newline := ""
			end

			l_schema := database.schema
			l_tables := l_schema.tables

			Result.append ("{")
			Result.append (l_newline)

			l_first := True
			across l_tables as ic loop
				if not l_first then
					Result.append (",")
					Result.append (l_newline)
				end
				l_first := False

				Result.append (l_indent)
				Result.append ("%"")
				Result.append (escape_json_string (ic))
				Result.append ("%": ")
				Result.append (table_json_string (ic))
			end

			Result.append (l_newline)
			Result.append ("}")
		end

feature -- SQL Dump Export

	table_to_sql (a_table_name: READABLE_STRING_GENERAL; a_file_path: READABLE_STRING_GENERAL)
			-- Export table to SQL file (CREATE TABLE + INSERT statements)
		require
			table_name_not_empty: not a_table_name.is_empty
			file_path_not_empty: not a_file_path.is_empty
		local
			l_file: PLAIN_TEXT_FILE
			l_content: STRING_32
		do
			l_content := table_sql_string (a_table_name)
			create l_file.make_create_read_write (a_file_path.to_string_32)
			l_file.put_string (l_content.to_string_8)
			l_file.close
		end

	table_sql_string (a_table_name: READABLE_STRING_GENERAL): STRING_32
			-- Get table as SQL statements (CREATE TABLE + INSERTs)
			-- All statements are single-line for reliable parsing
		require
			table_name_not_empty: not a_table_name.is_empty
		local
			l_schema: SIMPLE_SQL_RESULT
			l_result: SIMPLE_SQL_RESULT
			l_row: SIMPLE_SQL_ROW
			l_create_sql: STRING_32
			i: INTEGER
		do
			create Result.make (2048)

			-- Get CREATE TABLE statement
			l_schema := database.query (
				"SELECT sql FROM sqlite_master WHERE type='table' AND name='" +
				escape_sql_string (a_table_name.to_string_8) + "'"
			)
			if not l_schema.rows.is_empty then
				if attached l_schema.rows.first.string_value ("sql") as al_l_create then
					-- Normalize to single line (replace newlines with spaces)
					create l_create_sql.make_from_string (al_l_create.to_string_32)
					l_create_sql.replace_substring_all ("%N", " ")
					l_create_sql.replace_substring_all ("%R", " ")
					l_create_sql.replace_substring_all ("%T", " ")
					Result.append (l_create_sql)
					Result.append (";%N")
				end
			end

			-- Generate INSERT statements (already single-line)
			l_result := database.query ("SELECT * FROM " + a_table_name.to_string_8)

			across l_result.rows as ic loop
				l_row := ic
				Result.append ("INSERT INTO ")
				Result.append (a_table_name.to_string_32)
				Result.append (" VALUES (")

				from i := 1 until i > l_row.count loop
					if i > 1 then
						Result.append (", ")
					end
					Result.append (format_sql_value (l_row, i))
					i := i + 1
				end

				Result.append (");%N")
			end
		end

	database_to_sql (a_file_path: READABLE_STRING_GENERAL)
			-- Export entire database to SQL file
		require
			file_path_not_empty: not a_file_path.is_empty
		local
			l_file: PLAIN_TEXT_FILE
			l_content: STRING_32
		do
			l_content := database_sql_string
			create l_file.make_create_read_write (a_file_path.to_string_32)
			l_file.put_string (l_content.to_string_8)
			l_file.close
		end

	database_sql_string: STRING_32
			-- Get entire database as SQL dump string
		local
			l_schema: SIMPLE_SQL_SCHEMA
			l_tables: ARRAYED_LIST [STRING_8]
		do
			create Result.make (8192)

			Result.append ("-- SQLite Database Dump%N")
			Result.append ("-- Generated by SIMPLE_SQL_EXPORT%N%N")
			Result.append ("BEGIN TRANSACTION;%N%N")

			l_schema := database.schema
			l_tables := l_schema.tables

			across l_tables as ic loop
				Result.append ("-- Table: ")
				Result.append (ic.to_string_32)
				Result.append ("%N")
				Result.append (table_sql_string (ic))
				Result.append ("%N")
			end

			Result.append ("COMMIT;%N")
		end

feature {NONE} -- CSV Implementation

	escape_csv_value (a_value: READABLE_STRING_GENERAL): STRING_32
			-- Escape value for CSV (quote if contains delimiter or quote)
		local
			l_needs_quote: BOOLEAN
		do
			create Result.make_from_string (a_value.to_string_32)

			l_needs_quote := a_value.has (csv_delimiter) or
							a_value.has (csv_quote_char) or
							a_value.has ('%N') or
							a_value.has ('%R')

			if l_needs_quote then
				Result.replace_substring_all (csv_quote_char.out, csv_quote_char.out + csv_quote_char.out)
				Result.prepend_character (csv_quote_char)
				Result.append_character (csv_quote_char)
			end
		end

	format_csv_value (a_row: SIMPLE_SQL_ROW; a_index: INTEGER): STRING_32
			-- Format row value for CSV output
			-- BLOBs are encoded as "blob:HEXDATA" for later identification
		local
			l_col_name: STRING_32
		do
			l_col_name := a_row.column_name (a_index)

			if a_row.is_null (l_col_name) then
				Result := ""
			elseif attached {INTEGER_64} a_row [a_index] as al_l_int then
				create Result.make_from_string (l_int.out)
			elseif attached {REAL_64} a_row [a_index] as al_l_real then
				create Result.make_from_string (l_real.out)
			elseif attached {MANAGED_POINTER} a_row [a_index] as al_l_blob then
				-- Encode BLOB as "blob:HEXDATA" for CSV
				create Result.make (l_blob.count * 2 + 10)
				Result.append ("blob:")
				Result.append (blob_to_hex (l_blob))
			elseif attached {READABLE_STRING_GENERAL} a_row [a_index] as al_l_string then
				Result := escape_csv_value (l_string)
			else
				Result := ""
			end
		end

feature {NONE} -- JSON Implementation

	escape_json_string (a_value: READABLE_STRING_GENERAL): STRING_32
			-- Escape string for JSON
		local
			i: INTEGER
			c: CHARACTER_32
		do
			create Result.make (a_value.count)
			from i := 1 until i > a_value.count loop
				c := a_value.item (i)
				inspect c
				when '"' then Result.append ("\%"")
				when '\' then Result.append ("\\")
				when '%N' then Result.append ("\n")
				when '%R' then Result.append ("\r")
				when '%T' then Result.append ("\t")
				else Result.append_character (c)
				end
				i := i + 1
			end
		end

	format_json_value (a_row: SIMPLE_SQL_ROW; a_index: INTEGER): STRING_32
			-- Format row value for JSON output
			-- BLOBs are encoded as {"$blob": "HEXDATA"} object for later identification
		local
			l_col_name: STRING_32
		do
			l_col_name := a_row.column_name (a_index)

			if a_row.is_null (l_col_name) then
				Result := "null"
			elseif attached {INTEGER_64} a_row [a_index] as al_l_int then
				create Result.make_from_string (l_int.out)
			elseif attached {REAL_64} a_row [a_index] as al_l_real then
				create Result.make_from_string (l_real.out)
			elseif attached {MANAGED_POINTER} a_row [a_index] as al_l_blob then
				-- Encode BLOB as JSON object with $blob marker
				create Result.make (l_blob.count * 2 + 20)
				Result.append ("{%"$blob%": %"")
				Result.append (blob_to_hex (l_blob))
				Result.append ("%"}")
			elseif attached {READABLE_STRING_GENERAL} a_row [a_index] as al_l_string then
				create Result.make (l_string.count + 10)
				Result.append_character ('"')
				Result.append (escape_json_string (l_string))
				Result.append_character ('"')
			else
				Result := "null"
			end
		end

feature {NONE} -- SQL Implementation

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

	format_sql_value (a_row: SIMPLE_SQL_ROW; a_index: INTEGER): STRING_32
			-- Format row value for SQL INSERT statement
			-- BLOBs are encoded using SQLite X'HEXDATA' syntax
		local
			l_col_name: STRING_32
		do
			l_col_name := a_row.column_name (a_index)

			if a_row.is_null (l_col_name) then
				Result := "NULL"
			elseif attached {INTEGER_64} a_row [a_index] as al_l_int then
				create Result.make_from_string (l_int.out)
			elseif attached {REAL_64} a_row [a_index] as al_l_real then
				create Result.make_from_string (l_real.out)
			elseif attached {MANAGED_POINTER} a_row [a_index] as al_l_blob then
				-- Encode BLOB using SQLite hex literal syntax: X'...'
				create Result.make (l_blob.count * 2 + 4)
				Result.append ("X'")
				Result.append (blob_to_hex (l_blob))
				Result.append_character ('%'')
			elseif attached {READABLE_STRING_GENERAL} a_row [a_index] as al_l_string then
				create Result.make (l_string.count + 10)
				Result.append_character ('%'')
				Result.append (escape_sql_string (l_string.to_string_8).to_string_32)
				Result.append_character ('%'')
			else
				Result := "NULL"
			end
		end

feature {NONE} -- BLOB Encoding

	blob_to_hex (a_blob: MANAGED_POINTER): STRING_32
			-- Convert BLOB to uppercase hexadecimal string
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
		SIMPLE_SQL - High-level SQLite API for Eiffel
	]"

end
