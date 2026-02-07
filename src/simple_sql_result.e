note
	description: "[
		Query result wrapper providing easy access to SQLite result rows.
		Automatically collects all rows for simple iteration.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_RESULT

create
	make,
	make_empty

feature {NONE} -- Initialization

	make (a_sql: READABLE_STRING_8; a_database: SQLITE_DATABASE)
			-- Execute query and collect results
		require
			sql_not_empty: not a_sql.is_empty
			database_attached: a_database /= Void
			database_is_readable: a_database.is_readable
		local
			l_statement: SQLITE_QUERY_STATEMENT
		do
			create rows.make (Initial_capacity)
			create l_statement.make (a_sql, a_database)
			l_statement.execute (agent collect_row)
		ensure
			rows_attached: rows /= Void
		end

	make_empty
			-- Create empty result (for error cases)
		do
			create rows.make (0)
		ensure
			is_empty: count = 0
		end

feature -- Access

	rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			-- All result rows

feature -- Measurement

	count: INTEGER
			-- Number of rows in result
		do
			Result := rows.count
		ensure
			non_negative: Result >= 0
		end

feature -- Status report

	is_empty: BOOLEAN
			-- Has no rows?
		do
			Result := rows.is_empty
		ensure
			definition: Result = (count = 0)
		end

feature -- Access

	first: SIMPLE_SQL_ROW
			-- First row
		require
			not_is_empty: not is_empty
		do
			Result := rows.first
		ensure
			result_attached: Result /= Void
		end

	last: SIMPLE_SQL_ROW
			-- Last row
		require
			not_is_empty: not is_empty
		do
			Result := rows.last
		ensure
			result_attached: Result /= Void
		end

	item alias "[]" (a_i: INTEGER): SIMPLE_SQL_ROW
			-- Row at index `i'
		require
			valid_index: a_i >= 1 and a_i <= count
		do
			Result := rows.i_th (a_i)
		ensure
			result_attached: Result /= Void
		end

feature -- Model Queries

	rows_model: MML_SEQUENCE [SIMPLE_SQL_ROW]
			-- Mathematical model of result rows in order.
		do
			create Result
			across rows as ic loop
				Result := Result & ic
			end
		ensure
			count_matches: Result.count = rows.count
		end

feature {NONE} -- Implementation

	collect_row (a_row: SQLITE_RESULT_ROW): BOOLEAN
			-- Collect row data (callback for query execution)
		local
			l_sql_row: SIMPLE_SQL_ROW
			i: NATURAL
		do
			create l_sql_row.make (a_row.count.to_integer_32)
			from
				i := 1
			until
				i > a_row.count
			loop
				l_sql_row.add_column (a_row.column_name (i).to_string_8, a_row [i])
				i := i + 1
			end
			rows.extend (l_sql_row)
			Result := False -- Continue processing
		end

feature {NONE} -- Constants

	Initial_capacity: INTEGER = 32
			-- Initial capacity for rows list

invariant
	rows_attached: rows /= Void

	-- Model consistency
	model_rows_count: rows_model.count = count

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_SQL - High-level SQLite API for Eiffel
	]"

end
