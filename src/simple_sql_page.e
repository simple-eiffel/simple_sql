note
	description: "[
		Result of a paginated query.

		Contains items for the current page plus cursor for next page.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_PAGE

create
	make

feature {NONE} -- Initialization

	make (a_items: ARRAYED_LIST [SIMPLE_SQL_ROW]; a_next_cursor: detachable STRING_8; a_has_more: BOOLEAN)
			-- Initialize with items and cursor.
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
		do
			Result := items.count
		end

	is_empty: BOOLEAN
			-- No items in this page?
		do
			Result := items.is_empty
		end

	is_last_page: BOOLEAN
			-- Is this the last page?
		do
			Result := not has_more
		end

feature -- Iteration

	first: detachable SIMPLE_SQL_ROW
			-- First item.
		do
			if not items.is_empty then
				Result := items.first
			end
		end

	last: detachable SIMPLE_SQL_ROW
			-- Last item.
		do
			if not items.is_empty then
				Result := items.last
			end
		end

invariant
	items_attached: items /= Void
	cursor_when_more: has_more implies next_cursor /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
