note
	description: "[
		A result container holding both main and related data from an eager-loaded
		query execution.
		Organizes related result sets by table name and filters them by the
		_eager_fk column to return rows belonging to a specific main row ID.
		Delivers the combined output of SIMPLE_SQL_EAGER_LOADER for the simple_sql library.
	]"
	purpose: "Hold and provide access to main and related eager-loaded query results"
	collaborators: "SIMPLE_SQL_EAGER_LOADER, SIMPLE_SQL_RESULT, SIMPLE_SQL_ROW, MML_MAP"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_EAGER_RESULT

create
	make

feature {NONE} -- Initialization

	make (a_main: SIMPLE_SQL_RESULT; a_related: HASH_TABLE [SIMPLE_SQL_RESULT, STRING_8])
			-- Initialize with main result and related results.
		note
			semantic_role: "[
				Assembles the complete eager-loaded
				result from main and related query
				results.
			]"
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
		note
			semantic_role: "[
				Convenience accessor delegating to the
				main result's row list.
			]"
		do
			Result := main_result.rows
		end

	related_results: HASH_TABLE [SIMPLE_SQL_RESULT, STRING_8]
			-- All related results keyed by table name.

	related (a_table: READABLE_STRING_8): detachable SIMPLE_SQL_RESULT
			-- Get all related rows for a table.
		note
			semantic_role: "[
				Looks up the full related result set
				by table name.
			]"
		require
			table_not_empty: not a_table.is_empty
		do
			Result := related_results.item (a_table.to_string_8)
		end

	related_for (a_table: READABLE_STRING_8; a_main_id: INTEGER_64): ARRAYED_LIST [SIMPLE_SQL_ROW]
			-- Get related rows for a specific main row ID.
			-- Uses the _eager_fk column added during eager loading.
		note
			semantic_role: "[
				Filters related rows by _eager_fk to
				return only those belonging to a
				specific main row.
			]"
		require
			table_not_empty: not a_table.is_empty
		local
			l_result: detachable SIMPLE_SQL_RESULT
		do
			create Result.make (5)
			l_result := related_results.item (a_table.to_string_8)
			if attached l_result as al_r then
				across al_r.rows as ic loop
					if ic.integer_64_value ("_eager_fk") = a_main_id then
						Result.extend (ic)
					end
				end
			end
		end

feature -- Model Queries

	related_results_model: MML_MAP [STRING_8, SIMPLE_SQL_RESULT]
			-- Mathematical model of related results by table name.
		note
			semantic_role: "[
				Materializes the related results hash
				table as an MML_MAP for contract-based
				verification.
			]"
		do
			create Result
			from related_results.start until related_results.after loop
				Result := Result.updated (related_results.key_for_iteration, related_results.item_for_iteration)
				related_results.forth
			end
		ensure
			count_matches: Result.count = related_results.count
		end

feature -- Status

	main_count: INTEGER
			-- Number of main rows.
		note
			semantic_role: "[
				Convenience count accessor for the
				main result set.
			]"
		do
			Result := main_result.rows.count
		end

	is_empty: BOOLEAN
			-- No main rows?
		note
			semantic_role: "[
				Emptiness predicate for the main
				result set.
			]"
		do
			Result := main_result.rows.is_empty
		end

	has_related (a_table: READABLE_STRING_8): BOOLEAN
			-- Do we have related data for this table?
		note
			semantic_role: "[
				Checks whether a related table was
				included in the eager load.
			]"
		require
			table_not_empty: not a_table.is_empty
		do
			Result := related_results.has (a_table.to_string_8)
		end

	related_count (a_table: READABLE_STRING_8): INTEGER
			-- Total number of related rows for a table.
		note
			semantic_role: "[
				Returns the total row count across all
				main rows for a related table.
			]"
		require
			table_not_empty: not a_table.is_empty
		local
			l_result: detachable SIMPLE_SQL_RESULT
		do
			l_result := related_results.item (a_table.to_string_8)
			if attached l_result as al_r then
				Result := al_r.rows.count
			end
		end

	related_count_for (a_table: READABLE_STRING_8; a_main_id: INTEGER_64): INTEGER
			-- Number of related rows for a specific main row.
		note
			semantic_role: "[
				Counts related rows filtered by
				_eager_fk for a specific main row.
			]"
		require
			table_not_empty: not a_table.is_empty
		local
			l_result: detachable SIMPLE_SQL_RESULT
		do
			l_result := related_results.item (a_table.to_string_8)
			if attached l_result as al_r then
				across al_r.rows as ic loop
					if ic.integer_64_value ("_eager_fk") = a_main_id then
						Result := Result + 1
					end
				end
			end
		end

invariant
	main_result_attached: main_result /= Void
	related_results_attached: related_results /= Void
	model_count_consistent: related_results_model.count = related_results.count

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
