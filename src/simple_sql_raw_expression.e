note
	description: "Wrapper for raw SQL expressions that should not be escaped"
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

end
