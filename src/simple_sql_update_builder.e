note
	description: "[
		Fluent builder for SQL UPDATE statements with SET clause construction,
		WHERE clause filtering, and arithmetic helpers. Supports raw SQL
		expressions via SIMPLE_SQL_RAW_EXPRESSION for computed assignments
		like counter increments.

		Provides convenience methods for common patterns: increment/decrement
		by 1 or by amount, set to NULL, and set to raw expression.
	]"
	purpose: "Fluent UPDATE statement construction with SET clauses and arithmetic helpers"
	collaborators: "SIMPLE_SQL_QUERY_BUILDER, SIMPLE_SQL_DATABASE, SIMPLE_SQL_RAW_EXPRESSION"
	design_pattern: "Builder"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_UPDATE_BUILDER

inherit
	SIMPLE_SQL_QUERY_BUILDER

create
	make,
	make_with_database

feature {NONE} -- Initialization

	make
			-- Create empty update builder
		note
			semantic_role: "[
				Initializes empty table, SET clause, and
				WHERE clause storage.
			]"
		do
			create table_name.make_empty
			create set_clauses.make (10)
			create where_clauses.make (10)
		end

	make_with_database (a_database: SIMPLE_SQL_DATABASE)
			-- Create with database for execution
		note
			semantic_role: "[
				Combines builder initialization with
				database attachment for immediate
				execution capability.
			]"
		require
			database_open: a_database.is_open
		do
			make
			set_database (a_database)
		ensure
			database_set: database = a_database
		end

feature -- Table

	table (a_table: READABLE_STRING_8): like Current
			-- Set the target table
		note
			semantic_role: "[
				Specifies the UPDATE target table,
				returning Current for fluent chaining.
			]"
			modifies: "table_name"
		require
			table_not_empty: not a_table.is_empty
		do
			table_name := a_table.to_string_8
			Result := Current
		ensure
			table_set: table_name.same_string (a_table)
		end

	update (a_table: READABLE_STRING_8): like Current
			-- Alias for table - more natural reading
		note
			semantic_role: "[
				Natural-language alias for table selection
				reading as update('users').
			]"
			modifies: "table_name"
		require
			table_not_empty: not a_table.is_empty
		do
			Result := table (a_table)
		ensure
			table_set: table_name.same_string (a_table)
		end

feature -- SET Clauses

	set (a_column: READABLE_STRING_8; a_value: detachable ANY): like Current
			-- Set column = value
		note
			semantic_role: "[
				Adds a column assignment to the SET
				clause using value_to_sql conversion.
			]"
			modifies: "set_clauses"
		require
			column_not_empty: not a_column.is_empty
		do
			set_clauses.extend ([a_column.to_string_8, a_value])
			Result := Current
		end

	set_null (a_column: READABLE_STRING_8): like Current
			-- Set column = NULL
		note
			semantic_role: "[
				Convenience for setting a column to SQL
				NULL.
			]"
			modifies: "set_clauses"
		require
			column_not_empty: not a_column.is_empty
		do
			set_clauses.extend ([a_column.to_string_8, Void])
			Result := Current
		end

	set_expression (a_column: READABLE_STRING_8; a_expression: READABLE_STRING_8): like Current
			-- Set column = raw SQL expression (not escaped)
			-- Use for things like: set_expression("counter", "counter + 1")
		note
			semantic_role: "[
				Assigns a raw SQL expression bypassing
				value escaping for computed updates.
			]"
			modifies: "set_clauses"
		require
			column_not_empty: not a_column.is_empty
			expression_not_empty: not a_expression.is_empty
		do
			set_clauses.extend ([a_column.to_string_8, create {SIMPLE_SQL_RAW_EXPRESSION}.make (a_expression)])
			Result := Current
		end

	increment (a_column: READABLE_STRING_8): like Current
			-- Increment column by 1
		note
			semantic_role: "[
				Convenience for column = column + 1
				pattern.
			]"
			modifies: "set_clauses"
		require
			column_not_empty: not a_column.is_empty
		do
			Result := set_expression (a_column, a_column + " + 1")
		end

	increment_by (a_column: READABLE_STRING_8; a_amount: INTEGER): like Current
			-- Increment column by amount
		note
			semantic_role: "[
				Convenience for column = column + N
				arithmetic update.
			]"
			modifies: "set_clauses"
		require
			column_not_empty: not a_column.is_empty
		do
			Result := set_expression (a_column, a_column + " + " + a_amount.out)
		end

	decrement (a_column: READABLE_STRING_8): like Current
			-- Decrement column by 1
		note
			semantic_role: "[
				Convenience for column = column - 1
				pattern.
			]"
			modifies: "set_clauses"
		require
			column_not_empty: not a_column.is_empty
		do
			Result := set_expression (a_column, a_column + " - 1")
		end

	decrement_by (a_column: READABLE_STRING_8; a_amount: INTEGER): like Current
			-- Decrement column by amount
		note
			semantic_role: "[
				Convenience for column = column - N
				arithmetic update.
			]"
			modifies: "set_clauses"
		require
			column_not_empty: not a_column.is_empty
		do
			Result := set_expression (a_column, a_column + " - " + a_amount.out)
		end

feature -- WHERE Clauses

	where (a_condition: READABLE_STRING_8): like Current
			-- Set the WHERE condition (replaces any existing)
		note
			semantic_role: "[
				Sets the primary WHERE filter, replacing
				any previous conditions.
			]"
			modifies: "where_clauses"
		require
			condition_not_empty: not a_condition.is_empty
		do
			where_clauses.wipe_out
			where_clauses.extend ([a_condition.to_string_8, ""])
			Result := Current
		end

	where_equals (a_column: READABLE_STRING_8; a_value: detachable ANY): like Current
			-- Add WHERE column = value
		note
			semantic_role: "[
				Convenience for single-column equality
				filter replacing previous conditions.
			]"
			modifies: "where_clauses"
		require
			column_not_empty: not a_column.is_empty
		do
			where_clauses.wipe_out
			where_clauses.extend ([a_column.to_string_8 + " = " + value_to_sql (a_value), ""])
			Result := Current
		end

	where_id (a_id: INTEGER_64): like Current
			-- Convenience: WHERE id = value
		note
			semantic_role: "[
				Primary key filter shortcut for the common
				WHERE id = N pattern.
			]"
			modifies: "where_clauses"
		do
			Result := where_equals ("id", a_id)
		end

	and_where (a_condition: READABLE_STRING_8): like Current
			-- Add AND condition
		note
			semantic_role: "[
				Appends an AND-connected condition to the
				existing WHERE clause.
			]"
			modifies: "where_clauses"
		require
			condition_not_empty: not a_condition.is_empty
		do
			where_clauses.extend ([a_condition.to_string_8, "AND"])
			Result := Current
		end

	and_where_equals (a_column: READABLE_STRING_8; a_value: detachable ANY): like Current
			-- Add AND column = value
		note
			semantic_role: "[
				Appends an AND-connected equality
				condition.
			]"
			modifies: "where_clauses"
		require
			column_not_empty: not a_column.is_empty
		do
			where_clauses.extend ([a_column.to_string_8 + " = " + value_to_sql (a_value), "AND"])
			Result := Current
		end

	or_where (a_condition: READABLE_STRING_8): like Current
			-- Add OR condition
		note
			semantic_role: "[
				Appends an OR-connected condition to the
				existing WHERE clause.
			]"
			modifies: "where_clauses"
		require
			condition_not_empty: not a_condition.is_empty
		do
			where_clauses.extend ([a_condition.to_string_8, "OR"])
			Result := Current
		end

	or_where_equals (a_column: READABLE_STRING_8; a_value: detachable ANY): like Current
			-- Add OR column = value
		note
			semantic_role: "[
				Appends an OR-connected equality
				condition.
			]"
			modifies: "where_clauses"
		require
			column_not_empty: not a_column.is_empty
		do
			where_clauses.extend ([a_column.to_string_8 + " = " + value_to_sql (a_value), "OR"])
			Result := Current
		end

	where_null (a_column: READABLE_STRING_8): like Current
			-- Add WHERE column IS NULL
		note
			semantic_role: "[
				NULL-testing filter replacing previous
				conditions.
			]"
			modifies: "where_clauses"
		require
			column_not_empty: not a_column.is_empty
		do
			where_clauses.wipe_out
			where_clauses.extend ([a_column.to_string_8 + " IS NULL", ""])
			Result := Current
		end

	where_not_null (a_column: READABLE_STRING_8): like Current
			-- Add WHERE column IS NOT NULL
		note
			semantic_role: "[
				Non-NULL testing filter replacing previous
				conditions.
			]"
			modifies: "where_clauses"
		require
			column_not_empty: not a_column.is_empty
		do
			where_clauses.wipe_out
			where_clauses.extend ([a_column.to_string_8 + " IS NOT NULL", ""])
			Result := Current
		end

	where_in (a_column: READABLE_STRING_8; a_values: ARRAY [detachable ANY]): like Current
			-- Add WHERE column IN (values)
		note
			semantic_role: "[
				Set membership filter replacing previous
				conditions.
			]"
			modifies: "where_clauses"
		require
			column_not_empty: not a_column.is_empty
			values_not_empty: not a_values.is_empty
		local
			l_sql: STRING_8
			i: INTEGER
		do
			create l_sql.make (50)
			l_sql.append (a_column.to_string_8)
			l_sql.append (" IN (")
			from i := a_values.lower until i > a_values.upper loop
				if i > a_values.lower then
					l_sql.append (", ")
				end
				l_sql.append (value_to_sql (a_values [i]))
				i := i + 1
			end
			l_sql.append (")")
			where_clauses.wipe_out
			where_clauses.extend ([l_sql, ""])
			Result := Current
		end

feature -- Status (for preconditions)

	has_table: BOOLEAN
			-- Has a table been specified?
		note
			semantic_role: "[
				Table specification predicate guarding
				UPDATE execution.
			]"
		do
			Result := not table_name.is_empty
		end

	has_set_clauses: BOOLEAN
			-- Are there SET clauses?
		note
			semantic_role: "[
				SET clause presence predicate ensuring at
				least one assignment exists.
			]"
		do
			Result := not set_clauses.is_empty
		end

feature -- Execution

	execute: INTEGER
			-- Execute update and return number of rows affected
		note
			semantic_role: "[
				Executes the UPDATE statement and returns
				SQLite changes_count.
			]"
		require
			has_database: has_database
			has_table: has_table
			has_set_clauses: has_set_clauses
		do
			if attached database as al_l_db then
				al_l_db.execute (to_sql)
				if not al_l_db.has_error then
					Result := al_l_db.changes_count
				end
			end
		end

feature -- Reset

	reset
			-- Clear all builder state
		note
			semantic_role: "[
				Returns builder to empty state for reuse
				with a different UPDATE.
			]"
			modifies: "table_name, set_clauses, where_clauses"
		do
			table_name.wipe_out
			set_clauses.wipe_out
			where_clauses.wipe_out
		ensure
			table_empty: table_name.is_empty
			set_empty: set_clauses.is_empty
			where_empty: where_clauses.is_empty
		end

feature -- Output

	to_sql: STRING_8
			-- Generate SQL UPDATE statement
		note
			semantic_role: "[
				Assembles UPDATE SET WHERE from accumulated
				clauses with raw expression support.
			]"
		local
			i: INTEGER
		do
			create Result.make (200)

			-- UPDATE table
			Result.append ("UPDATE ")
			Result.append (table_name)

			-- SET clauses
			Result.append (" SET ")
			from i := 1 until i > set_clauses.count loop
				if i > 1 then
					Result.append (", ")
				end
				Result.append (set_clauses [i].column)
				Result.append (" = ")
				if attached {SIMPLE_SQL_RAW_EXPRESSION} set_clauses [i].value as al_l_raw then
					Result.append (al_l_raw.expression)
				else
					Result.append (value_to_sql (set_clauses [i].value))
				end
				i := i + 1
			end

			-- WHERE
			if not where_clauses.is_empty then
				Result.append (" WHERE ")
				from i := 1 until i > where_clauses.count loop
					if i > 1 and then not where_clauses [i].connector.is_empty then
						Result.append (" ")
						Result.append (where_clauses [i].connector)
						Result.append (" ")
					end
					Result.append (where_clauses [i].condition)
					i := i + 1
				end
			end
		end

feature -- Model Queries

	set_clauses_model: MML_SEQUENCE [TUPLE [column: STRING_8; value: detachable ANY]]
			-- Mathematical model of SET assignments in order.
		note
			semantic_role: "[
				MML specification of SET assignments for
				formal postcondition verification.
			]"
		do
			create Result
			across set_clauses as ic loop
				Result := Result & ic
			end
		ensure
			count_matches: Result.count = set_clauses.count
		end

	where_clauses_model: MML_SEQUENCE [TUPLE [condition: STRING_8; connector: STRING_8]]
			-- Mathematical model of WHERE conditions in order.
		note
			semantic_role: "[
				MML specification of WHERE conditions for
				formal postcondition verification.
			]"
		do
			create Result
			across where_clauses as ic loop
				Result := Result & ic
			end
		ensure
			count_matches: Result.count = where_clauses.count
		end

feature {NONE} -- Implementation

	table_name: STRING_8
			-- Target table name

	set_clauses: ARRAYED_LIST [TUPLE [column: STRING_8; value: detachable ANY]]
			-- SET column = value pairs

	where_clauses: ARRAYED_LIST [TUPLE [condition: STRING_8; connector: STRING_8]]
			-- WHERE conditions with connectors

invariant
	table_name_attached: attached table_name
	set_clauses_attached: attached set_clauses
	where_clauses_attached: attached where_clauses

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
