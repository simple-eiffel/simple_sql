note
	description: "Base class for fluent SQL query builders"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SIMPLE_SQL_QUERY_BUILDER

feature -- Access

	database: detachable SIMPLE_SQL_DATABASE
			-- Database for execution (optional - can generate SQL only)

	to_sql: STRING_8
			-- Generate the SQL string
		deferred
		ensure
			result_not_empty: not Result.is_empty
		end

feature -- Element Change

	set_database (a_database: SIMPLE_SQL_DATABASE)
			-- Set database for execution
		require
			database_open: a_database.is_open
		do
			database := a_database
		ensure
			database_set: database = a_database
		end

feature -- Status

	has_database: BOOLEAN
			-- Is a database set for execution?
		do
			Result := attached database
		end

feature {SIMPLE_SQL_QUERY_BUILDER} -- Implementation

	escaped_string (a_string: READABLE_STRING_GENERAL): STRING_8
			-- Escape `a_string` for safe SQL inclusion
			-- Single quotes are doubled, result is wrapped in quotes
		local
			i: INTEGER
			c: CHARACTER_32
		do
			create Result.make (a_string.count + 10)
			Result.append_character ('%'')
			from i := 1 until i > a_string.count loop
				c := a_string.item (i)
				if c = '%'' then
					Result.append_character ('%'')
					Result.append_character ('%'')
				else
					Result.append_character (c.to_character_8)
				end
				i := i + 1
			end
			Result.append_character ('%'')
		ensure
			starts_with_quote: Result.item (1) = '%''
			ends_with_quote: Result.item (Result.count) = '%''
		end

	value_to_sql (a_value: detachable ANY): STRING_8
			-- Convert `a_value` to SQL literal representation
		do
			if a_value = Void then
				Result := "NULL"
			elseif attached {BOOLEAN} a_value as l_bool then
				if l_bool then
					Result := "1"
				else
					Result := "0"
				end
			elseif attached {INTEGER_8} a_value as l_int then
				Result := l_int.out
			elseif attached {INTEGER_16} a_value as l_int then
				Result := l_int.out
			elseif attached {INTEGER_32} a_value as l_int then
				Result := l_int.out
			elseif attached {INTEGER_64} a_value as l_int then
				Result := l_int.out
			elseif attached {NATURAL_8} a_value as l_nat then
				Result := l_nat.out
			elseif attached {NATURAL_16} a_value as l_nat then
				Result := l_nat.out
			elseif attached {NATURAL_32} a_value as l_nat then
				Result := l_nat.out
			elseif attached {NATURAL_64} a_value as l_nat then
				Result := l_nat.out
			elseif attached {REAL_32} a_value as l_real then
				Result := l_real.out
			elseif attached {REAL_64} a_value as l_real then
				Result := l_real.out
			elseif attached {READABLE_STRING_GENERAL} a_value as l_string then
				Result := escaped_string (l_string)
			else
				-- Unknown type, use string representation
				Result := escaped_string (a_value.out)
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	identifier (a_name: READABLE_STRING_8): STRING_8
			-- Quote identifier if it contains special characters or is a reserved word
			-- Uses double quotes for SQL standard identifier quoting
		do
			if needs_quoting (a_name) then
				create Result.make (a_name.count + 2)
				Result.append_character ('"')
				Result.append_string_general (a_name)
				Result.append_character ('"')
			else
				Result := a_name.to_string_8
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	needs_quoting (a_name: READABLE_STRING_8): BOOLEAN
			-- Does `a_name` need quoting as an identifier?
		local
			i: INTEGER
			c: CHARACTER_8
		do
			if a_name.is_empty then
				Result := True
			else
				-- Check first character (must be letter or underscore)
				c := a_name.item (1)
				if not (c.is_alpha or c = '_') then
					Result := True
				else
					-- Check remaining characters
					from i := 2 until i > a_name.count or Result loop
						c := a_name.item (i)
						if not (c.is_alpha or c.is_digit or c = '_') then
							Result := True
						end
						i := i + 1
					end
				end
				-- Check for reserved words (basic set)
				if not Result then
					Result := is_reserved_word (a_name)
				end
			end
		end

	is_reserved_word (a_name: READABLE_STRING_8): BOOLEAN
			-- Is `a_name` a SQL reserved word?
		local
			l_upper: STRING_8
		do
			l_upper := a_name.to_string_8.as_upper
			Result := reserved_words.has (l_upper)
		end

	reserved_words: ARRAYED_SET [STRING_8]
			-- Common SQL reserved words
		once
			create Result.make (50)
			Result.compare_objects
			-- Add common reserved words
			Result.extend ("SELECT")
			Result.extend ("FROM")
			Result.extend ("WHERE")
			Result.extend ("INSERT")
			Result.extend ("UPDATE")
			Result.extend ("DELETE")
			Result.extend ("CREATE")
			Result.extend ("DROP")
			Result.extend ("TABLE")
			Result.extend ("INDEX")
			Result.extend ("VIEW")
			Result.extend ("AND")
			Result.extend ("OR")
			Result.extend ("NOT")
			Result.extend ("NULL")
			Result.extend ("TRUE")
			Result.extend ("FALSE")
			Result.extend ("ORDER")
			Result.extend ("BY")
			Result.extend ("GROUP")
			Result.extend ("HAVING")
			Result.extend ("LIMIT")
			Result.extend ("OFFSET")
			Result.extend ("JOIN")
			Result.extend ("LEFT")
			Result.extend ("RIGHT")
			Result.extend ("INNER")
			Result.extend ("OUTER")
			Result.extend ("ON")
			Result.extend ("AS")
			Result.extend ("IN")
			Result.extend ("BETWEEN")
			Result.extend ("LIKE")
			Result.extend ("IS")
			Result.extend ("EXISTS")
			Result.extend ("CASE")
			Result.extend ("WHEN")
			Result.extend ("THEN")
			Result.extend ("ELSE")
			Result.extend ("END")
			Result.extend ("PRIMARY")
			Result.extend ("KEY")
			Result.extend ("FOREIGN")
			Result.extend ("REFERENCES")
			Result.extend ("UNIQUE")
			Result.extend ("CHECK")
			Result.extend ("DEFAULT")
			Result.extend ("CONSTRAINT")
		end

end
