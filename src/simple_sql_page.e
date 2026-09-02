note
	description: "[
		A single page of query results with a cursor token for fetching subsequent pages.
		Carries an ARRAYED_LIST of SIMPLE_SQL_ROW items plus pagination state indicating
		whether more data exists and the opaque cursor needed to retrieve the next page.
		Enables bounded result delivery within the simple_sql library to prevent
		memory exhaustion on large result sets.
	]"
	purpose: "Carry one page of rows with cursor-based pagination state for query results"
	collaborators: "SIMPLE_SQL_ROW, MML_SEQUENCE"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_PAGE

create
	make

feature {NONE} -- Initialization

	make (a_items: ARRAYED_LIST [SIMPLE_SQL_ROW]; a_next_cursor: detachable STRING_8; a_has_more: BOOLEAN)
			-- Initialize with items and cursor.
		note
			semantic_role: "[
				Captures a page of results with its
				pagination cursor, binding item data
				to navigation state.
			]"
		require
			items_not_void: a_items /= Void
		do
			items := a_items
			next_cursor := a_next_cursor
			has_more := a_has_more
		ensure
			items_set: items = a_items
			cursor_set: next_cursor = a_next_cursor
			has_more_set: has_more = a_has_more
		end

feature -- Access

	items: ARRAYED_LIST [SIMPLE_SQL_ROW]
			-- Rows for this page.

	next_cursor: detachable STRING_8
			-- Cursor for fetching next page (Void if no more).

	has_more: BOOLEAN
			-- Are there more items after this page?

feature -- Status

	count: INTEGER
			-- Number of items in this page.
		note
			semantic_role: "[
				Reports item count for this page,
				distinct from the total query result
				size.
			]"
		do
			Result := items.count
		end

	is_empty: BOOLEAN
			-- No items in this page?
		note
			semantic_role: "[
				Emptiness predicate for pages that
				matched no rows in their cursor window.
			]"
		do
			Result := items.is_empty
		end

	is_last_page: BOOLEAN
			-- Is this the last page?
		note
			semantic_role: "[
				Terminal page detection used by pagination
				loops to know when to stop fetching.
			]"
		do
			Result := not has_more
		end

feature -- Model Queries

	items_model: MML_SEQUENCE [SIMPLE_SQL_ROW]
			-- Mathematical model of page items in order.
		note
			semantic_role: "[
				MML specification of page item ordering
				for formal contract verification.
			]"
		do
			create Result
			across items as ic loop
				Result := Result & ic
			end
		ensure
			count_matches: Result.count = items.count
		end

feature -- Iteration

	first: detachable SIMPLE_SQL_ROW
			-- First item.
		note
			semantic_role: "[
				First item access with empty-page safety,
				returning Void for empty pages.
			]"
		do
			if not items.is_empty then
				Result := items.first
			end
		end

	last: detachable SIMPLE_SQL_ROW
			-- Last item.
		note
			semantic_role: "[
				Last item access with empty-page safety,
				returning Void for empty pages.
			]"
		do
			if not items.is_empty then
				Result := items.last
			end
		end

invariant
	items_attached: items /= Void
	cursor_when_more: has_more implies next_cursor /= Void

	-- Model consistency
	model_items_count: items_model.count = count

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
