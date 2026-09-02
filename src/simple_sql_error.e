note
	description: "[
		Structured error information from an SQLite operation.
		Captures error code, message, and originating SQL while classifying
		errors into categories and detecting specific constraint violations.
		Provides diagnostic output for the simple_sql error-handling pipeline.
	]"
	purpose: "Represent and classify SQLite errors for contract-driven error handling"
	collaborators: "SIMPLE_SQL_ERROR_CODE"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_ERROR

create
	make,
	make_with_sql

feature {NONE} -- Initialization

	make (a_code: INTEGER; a_message: READABLE_STRING_GENERAL)
			-- Create error with code and message
		note
			semantic_role: "[
				Constructs error from SQLite result code
				and message with no SQL context.
			]"
		require
			message_not_void: a_message /= Void
		do
			code := a_code
			extended_code := a_code
			create message.make_from_string_general (a_message)
			create sql.make_empty
		ensure
			code_set: code = a_code
			extended_code_set: extended_code = a_code
			message_set: message.same_string_general (a_message)
			sql_empty: sql.is_empty
		end

	make_with_sql (a_code: INTEGER; a_message: READABLE_STRING_GENERAL; a_sql: READABLE_STRING_GENERAL)
			-- Create error with code, message, and originating SQL
		note
			semantic_role: "[
				Constructs error with the originating SQL
				statement for diagnostic context.
			]"
		require
			message_not_void: a_message /= Void
			sql_not_void: a_sql /= Void
		do
			code := a_code
			extended_code := a_code
			create message.make_from_string_general (a_message)
			create sql.make_from_string_general (a_sql)
		ensure
			code_set: code = a_code
			extended_code_set: extended_code = a_code
			message_set: message.same_string_general (a_message)
			sql_set: sql.same_string_general (a_sql)
		end

feature -- Access

	code: INTEGER
			-- Primary SQLite result code (lower 8 bits of extended_code)

	extended_code: INTEGER
			-- Full extended result code from SQLite

	message: STRING_32
			-- Error message from SQLite

	sql: STRING_32
			-- SQL statement that caused the error (may be empty)

feature -- Derived Access

	code_name: STRING_8
			-- Human-readable name for the error code
		note
			semantic_role: "[
				Maps primary error code to its
				SQLITE_* constant name.
			]"
		do
			Result := error_codes.name (code)
		ensure
			result_not_empty: not Result.is_empty
		end

	extended_code_name: STRING_8
			-- Human-readable name for the extended error code
		note
			semantic_role: "[
				Maps extended error code to its
				SQLITE_*_* constant name.
			]"
		do
			Result := error_codes.name (extended_code)
		ensure
			result_not_empty: not Result.is_empty
		end

feature -- Status

	is_constraint_violation: BOOLEAN
			-- Is this a constraint violation error?
		note
			semantic_role: "[
				Checks primary code against
				SQLITE_CONSTRAINT.
			]"
		do
			Result := code = error_codes.constraint
		end

	is_busy: BOOLEAN
			-- Is this a database busy/locked error?
		note
			semantic_role: "[
				Checks for SQLITE_BUSY or SQLITE_LOCKED
				indicating contention.
			]"
		do
			Result := code = error_codes.busy or code = error_codes.locked
		end

	is_readonly: BOOLEAN
			-- Is this a readonly database error?
		note
			semantic_role: "[
				Checks for SQLITE_READONLY indicating
				write attempt on read-only database.
			]"
		do
			Result := code = error_codes.readonly
		end

	is_io_error: BOOLEAN
			-- Is this an I/O error?
		note
			semantic_role: "[
				Checks for SQLITE_IOERR indicating
				disk-level failure.
			]"
		do
			Result := code = error_codes.ioerr
		end

	is_corrupt: BOOLEAN
			-- Is this a database corruption error?
		note
			semantic_role: "[
				Checks for SQLITE_CORRUPT indicating
				malformed database image.
			]"
		do
			Result := code = error_codes.corrupt
		end

	is_permission_error: BOOLEAN
			-- Is this a permission denied error?
		note
			semantic_role: "[
				Checks for SQLITE_PERM or SQLITE_AUTH
				permission failures.
			]"
		do
			Result := code = error_codes.perm or code = error_codes.auth
		end

feature -- Specific Constraint Violations

	is_unique_violation: BOOLEAN
			-- Is this a UNIQUE constraint violation?
		note
			semantic_role: "[
				Checks extended code for
				SQLITE_CONSTRAINT_UNIQUE.
			]"
		do
			Result := extended_code = error_codes.constraint_unique
		end

	is_primary_key_violation: BOOLEAN
			-- Is this a PRIMARY KEY constraint violation?
		note
			semantic_role: "[
				Checks extended code for
				SQLITE_CONSTRAINT_PRIMARYKEY.
			]"
		do
			Result := extended_code = error_codes.constraint_primarykey
		end

	is_foreign_key_violation: BOOLEAN
			-- Is this a FOREIGN KEY constraint violation?
		note
			semantic_role: "[
				Checks extended code for
				SQLITE_CONSTRAINT_FOREIGNKEY.
			]"
		do
			Result := extended_code = error_codes.constraint_foreignkey
		end

	is_not_null_violation: BOOLEAN
			-- Is this a NOT NULL constraint violation?
		note
			semantic_role: "[
				Checks extended code for
				SQLITE_CONSTRAINT_NOTNULL.
			]"
		do
			Result := extended_code = error_codes.constraint_notnull
		end

	is_check_violation: BOOLEAN
			-- Is this a CHECK constraint violation?
		note
			semantic_role: "[
				Checks extended code for
				SQLITE_CONSTRAINT_CHECK.
			]"
		do
			Result := extended_code = error_codes.constraint_check
		end

feature -- Output

	description: STRING_32
			-- Brief error description
		note
			semantic_role: "[
				Formats code name and message into
				a single diagnostic line.
			]"
		do
			create Result.make (code_name.count + message.count + 10)
			Result.append_string_general (code_name)
			Result.append_string_general (": ")
			Result.append (message)
		ensure
			result_not_empty: not Result.is_empty
		end

	full_description: STRING_32
			-- Full error description including SQL if available
		note
			semantic_role: "[
				Formats multi-line diagnostic output with
				code, message, and originating SQL.
			]"
		do
			create Result.make (100)
			Result.append_string_general ("Error: ")
			Result.append_string_general (code_name)
			if extended_code /= code then
				Result.append_string_general (" (")
				Result.append_string_general (extended_code_name)
				Result.append_string_general (")")
			end
			Result.append_string_general ("%NMessage: ")
			Result.append (message)
			if not sql.is_empty then
				Result.append_string_general ("%NSQL: ")
				Result.append (sql)
			end
		ensure
			result_not_empty: not Result.is_empty
		end

feature {NONE} -- Implementation

	error_codes: SIMPLE_SQL_ERROR_CODE
			-- Error code constants
		note
			semantic_role: "[
				Once-cached access to the error code
				enumeration singleton.
			]"
		once
			create Result
		end

feature -- Element Change

	set_extended_code (a_extended_code: INTEGER)
			-- Set extended code and update primary code
		note
			semantic_role: "[
				Updates both extended and primary codes
				maintaining their bit-mask relationship.
			]"
			modifies: "extended_code, code"
		do
			extended_code := a_extended_code
			code := error_codes.primary_code (a_extended_code)
		ensure
			extended_code_set: extended_code = a_extended_code
			code_derived: code = error_codes.primary_code (a_extended_code)
		end

invariant
	message_attached: message /= Void
	sql_attached: sql /= Void
	code_is_primary: code = error_codes.primary_code (extended_code)

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
