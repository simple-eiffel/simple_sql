note
	description: "[
		An abstract base class for fluent SQL query builders.
		Provides shared infrastructure for identifier quoting, value-to-SQL
		conversion, string escaping, and optional database attachment for
		direct execution, deferring `to_sql` to concrete descendants.
		Establishes the common builder foundation for the simple_sql library.
	]"
	purpose: "Provide shared SQL-generation utilities for concrete query builders"
	collaborators: "SIMPLE_SQL_DATABASE"
	design_pattern: "Template Method"
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
		note
			semantic_role: "[
				Attaches a live database connection
				enabling direct query execution.
			]"
			modifies: "database"
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
		note
			semantic_role: "[
				Execution readiness predicate guarding
				all execute operations.
			]"
		do
			Result := attached database
		end

feature {SIMPLE_SQL_QUERY_BUILDER} -- Implementation

	escaped_string (a_string: READABLE_STRING_GENERAL): STRING_8
			-- Escape `a_string` for safe SQL inclusion
			-- Single quotes are doubled, result is wrapped in quotes
		note
			semantic_role: "[
				SQL injection prevention by doubling
				single quotes and wrapping in quote
				delimiters.
			]"
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
			variant
				a_string.count - i + 1
			end
			Result.append_character ('%'')
		ensure
			starts_with_quote: Result.item (1) = '%''
			ends_with_quote: Result.item (Result.count) = '%''
		end

	value_to_sql (a_value: detachable ANY): STRING_8
			-- Convert `a_value` to SQL literal representation
		note
			semantic_role: "[
				Type-dispatching converter mapping
				Eiffel values to their SQL literal
				equivalents.
			]"
		do
			if a_value = Void then
				Result := "NULL"
			elseif attached {BOOLEAN} a_value as al_l_bool then
				if al_l_bool then
					Result := "1"
				else
					Result := "0"
				end
			elseif attached {INTEGER_8} a_value as al_l_int then
				Result := al_l_int.out
			elseif attached {INTEGER_16} a_value as al_l_int then
				Result := al_l_int.out
			elseif attached {INTEGER_32} a_value as al_l_int then
				Result := al_l_int.out
			elseif attached {INTEGER_64} a_value as al_l_int then
				Result := al_l_int.out
			elseif attached {NATURAL_8} a_value as al_l_nat then
				Result := al_l_nat.out
			elseif attached {NATURAL_16} a_value as al_l_nat then
				Result := al_l_nat.out
			elseif attached {NATURAL_32} a_value as al_l_nat then
				Result := al_l_nat.out
			elseif attached {NATURAL_64} a_value as al_l_nat then
				Result := al_l_nat.out
			elseif attached {REAL_32} a_value as al_l_real then
				Result := al_l_real.out
			elseif attached {REAL_64} a_value as al_l_real then
				Result := al_l_real.out
			elseif attached {READABLE_STRING_GENERAL} a_value as al_l_string then
				Result := escaped_string (al_l_string)
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
		note
			semantic_role: "[
				Conditionally wraps identifiers in
				double quotes when they conflict with
				SQL syntax.
			]"
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
		note
			semantic_role: "[
				Detects identifiers requiring quoting
				due to special characters or reserved
				word collision.
			]"
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
					variant
						a_name.count - i + 1
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
		note
			semantic_role: "[
				Case-insensitive check against the
				cached set of common SQL reserved words.
			]"
		local
			l_upper: STRING_8
		do
			l_upper := a_name.to_string_8.as_upper
			Result := reserved_words.has (l_upper)
		end

	reserved_words: ARRAYED_SET [STRING_8]
			-- Common SQL reserved words
		note
			semantic_role: "[
				Once-computed set of SQL reserved words
				used by identifier quoting logic.
			]"
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

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
