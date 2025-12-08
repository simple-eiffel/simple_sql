note
	description: "[
		Result container for eager-loaded queries.

		Holds the main result set plus all related data organized by table name.
		Provides convenient access to related rows for a given main row ID.

		Usage:
			results := loader.execute
			across results.main_rows as doc loop
				-- Get comments for this document
				comments := results.related_for ("comments", doc.integer_64_value ("id"))
			end
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_EAGER_RESULT

create
	make

feature {NONE} -- Initialization

	make (a_main: SIMPLE_SQL_RESULT; a_related: HASH_TABLE [SIMPLE_SQL_RESULT, STRING_8])
			-- Initialize with main result and related results.
		require
			main_not_void: a_main /= Void
			related_not_void: a_related /= Void
		do
			main_result := a_main
			related_results := a_related
		ensure
			main_set: main_result = a_main
			related_set: related_results = a_related
		end

feature -- Access

	main_result: SIMPLE_SQL_RESULT
			-- Main query result.

	main_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			-- Rows from main query.
		do
			Result := main_result.rows
		end

	related_results: HASH_TABLE [SIMPLE_SQL_RESULT, STRING_8]
			-- All related results keyed by table name.

	related (a_table: READABLE_STRING_8): detachable SIMPLE_SQL_RESULT
			-- Get all related rows for a table.
		require
			table_not_empty: not a_table.is_empty
		do
			Result := related_results.item (a_table.to_string_8)
		end

	related_for (a_table: READABLE_STRING_8; a_main_id: INTEGER_64): ARRAYED_LIST [SIMPLE_SQL_ROW]
			-- Get related rows for a specific main row ID.
			-- Uses the _eager_fk column added during eager loading.
		require
			table_not_empty: not a_table.is_empty
		local
			l_result: detachable SIMPLE_SQL_RESULT
		do
			create Result.make (5)
			l_result := related_results.item (a_table.to_string_8)
			if attached l_result as r then
				across r.rows as ic loop
					if ic.integer_64_value ("_eager_fk") = a_main_id then
						Result.extend (ic)
					end
				end
			end
		end

feature -- Status

	main_count: INTEGER
			-- Number of main rows.
		do
			Result := main_result.rows.count
		end

	is_empty: BOOLEAN
			-- No main rows?
		do
			Result := main_result.rows.is_empty
		end

	has_related (a_table: READABLE_STRING_8): BOOLEAN
			-- Do we have related data for this table?
		require
			table_not_empty: not a_table.is_empty
		do
			Result := related_results.has (a_table.to_string_8)
		end

	related_count (a_table: READABLE_STRING_8): INTEGER
			-- Total number of related rows for a table.
		require
			table_not_empty: not a_table.is_empty
		local
			l_result: detachable SIMPLE_SQL_RESULT
		do
			l_result := related_results.item (a_table.to_string_8)
			if attached l_result as r then
				Result := r.rows.count
			end
		end

	related_count_for (a_table: READABLE_STRING_8; a_main_id: INTEGER_64): INTEGER
			-- Number of related rows for a specific main row.
		require
			table_not_empty: not a_table.is_empty
		local
			l_result: detachable SIMPLE_SQL_RESULT
		do
			l_result := related_results.item (a_table.to_string_8)
			if attached l_result as r then
				across r.rows as ic loop
					if ic.integer_64_value ("_eager_fk") = a_main_id then
						Result := Result + 1
					end
				end
			end
		end

invariant
	main_result_attached: main_result /= Void
	related_results_attached: related_results /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
