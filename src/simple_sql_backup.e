note
	description: "[
		Utilities for backing up SQLite databases between memory and filesystem.
		Provides simple copy operations without relying on experimental backup API.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_BACKUP

feature -- Operations

	copy_memory_to_file (a_memory_db: SIMPLE_SQL_DATABASE; a_file_name: READABLE_STRING_GENERAL)
			-- Copy in-memory database to file
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
					l_file_db.execute (al_sql)
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
					a_memory_db.execute (al_sql)
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

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_SQL - High-level SQLite API for Eiffel
	]"

end
