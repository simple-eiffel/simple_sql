note
	description: "[
		An ITERATION_CURSOR adapter for SIMPLE_SQL_CURSOR enabling Eiffel
		across-loop syntax over query results.
		Delegates all cursor movement and row access to the underlying
		SIMPLE_SQL_CURSOR while providing convenience column accessors.
		Bridges the simple_sql cursor to the standard Eiffel iteration protocol.
	]"
	purpose: "Adapt SIMPLE_SQL_CURSOR to the ITERATION_CURSOR interface for across loops"
	collaborators: "SIMPLE_SQL_CURSOR, SIMPLE_SQL_ROW"
	design_pattern: "Adapter"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_CURSOR_ITERATOR

inherit
	ITERATION_CURSOR [SIMPLE_SQL_ROW]

create
	make

feature {NONE} -- Initialization

	make (a_cursor: SIMPLE_SQL_CURSOR)
			-- Initialize iterator with cursor
		note
			semantic_role: "[
				Wraps a SQL cursor and auto-starts it
				for immediate across-loop use.
			]"
		require
			cursor_attached: a_cursor /= Void
		do
			cursor := a_cursor
			if not cursor.is_started then
				cursor.start
			end
		ensure
			cursor_set: cursor = a_cursor
			cursor_started: cursor.is_started
		end

feature -- Access

	item: SIMPLE_SQL_ROW
			-- Current row
		note
			semantic_role: "[
				Delegates to the underlying cursor for
				the current row.
			]"
		do
			Result := cursor.item
		end

feature -- Convenience access (delegate to current row)

	string_value (a_name: STRING_8): STRING_32
			-- String value for column in current row
		note
			semantic_role: "[
				Shortcut delegating to the current
				row's string accessor by column name.
			]"
		require
			not_after: not after
			has_column: item.has_column (a_name)
		do
			Result := item.string_value (a_name)
		end

	integer_value (a_name: STRING_8): INTEGER
			-- Integer value for column in current row
		note
			semantic_role: "[
				Shortcut delegating to the current
				row's integer accessor by column name.
			]"
		require
			not_after: not after
			has_column: item.has_column (a_name)
		do
			Result := item.integer_value (a_name)
		end

	integer_64_value (a_name: STRING_8): INTEGER_64
			-- Integer_64 value for column in current row
		note
			semantic_role: "[
				Shortcut delegating to the current
				row's integer_64 accessor by column
				name.
			]"
		require
			not_after: not after
			has_column: item.has_column (a_name)
		do
			Result := item.integer_64_value (a_name)
		end

	real_value (a_name: STRING_8): REAL_64
			-- Real value for column in current row
		note
			semantic_role: "[
				Shortcut delegating to the current
				row's real accessor by column name.
			]"
		require
			not_after: not after
			has_column: item.has_column (a_name)
		do
			Result := item.real_value (a_name)
		end

	is_null (a_name: STRING_8): BOOLEAN
			-- Is column null in current row?
		note
			semantic_role: "[
				Shortcut delegating to the current
				row's null check by column name.
			]"
		require
			not_after: not after
			has_column: item.has_column (a_name)
		do
			Result := item.is_null (a_name)
		end

	column_value (a_name: STRING_8): detachable ANY
			-- Raw value for column in current row
		note
			semantic_role: "[
				Shortcut delegating to the current
				row's untyped value accessor by
				column name.
			]"
		require
			not_after: not after
			has_column: item.has_column (a_name)
		do
			Result := item.column_value (a_name)
		end

feature -- Status report

	after: BOOLEAN
			-- Is cursor past the last row?
		note
			semantic_role: "[
				Termination predicate for across-loop
				iteration control.
			]"
		do
			Result := cursor.after
		end

feature -- Cursor movement

	forth
			-- Move to next row
		note
			semantic_role: "[
				Advances the underlying cursor to the
				next row.
			]"
		do
			cursor.forth
		end

feature {NONE} -- Implementation

	cursor: SIMPLE_SQL_CURSOR
			-- The underlying cursor

invariant
	cursor_attached: cursor /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
