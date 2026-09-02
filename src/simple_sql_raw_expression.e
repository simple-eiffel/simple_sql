note
	description: "[
		A marker wrapper holding a raw SQL expression that must not be escaped.
		Preserves SQL fragments such as 'counter + 1' for direct embedding by
		query builders like SIMPLE_SQL_UPDATE_BUILDER.
		Separates literal values from computed expressions within the simple_sql
		builder API.
	]"
	purpose: "Carry a raw SQL fragment that bypasses value escaping in query builders"
	collaborators: ""
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_RAW_EXPRESSION

create
	make

feature {NONE} -- Initialization

	make (a_expression: READABLE_STRING_8)
			-- Create with raw SQL expression
		note
			semantic_role: "[
				Captures a raw SQL fragment for
				pass-through in query builders.
			]"
		require
			expression_not_empty: not a_expression.is_empty
		do
			expression := a_expression.to_string_8
		ensure
			expression_set: expression.same_string (a_expression)
		end

feature -- Access

	expression: STRING_8
			-- The raw SQL expression

invariant
	expression_not_empty: not expression.is_empty

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
