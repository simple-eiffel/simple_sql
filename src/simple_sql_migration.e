note
	description: "[
		Abstract base class for a versioned, bidirectional database schema migration.
		Encapsulates a version number and deferred up/down operations that concrete
		heirs implement with DDL/DML statements.
		Serves as the migration unit for simple_sql version-tracked schema evolution.
	]"
	purpose: "Define a single versioned schema change with upgrade and downgrade operations"
	collaborators: "SIMPLE_SQL_MIGRATION_RUNNER, SIMPLE_SQL_DATABASE"
	design_pattern: "Command"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SIMPLE_SQL_MIGRATION

feature -- Access

	version: INTEGER
			-- Migration version number (must be unique and sequential)
		deferred
		ensure
			positive: Result > 0
		end

	description: STRING_8
			-- Human-readable description of this migration
		deferred
		ensure
			not_empty: not Result.is_empty
		end

feature -- Operations

	up (a_database: SIMPLE_SQL_DATABASE)
			-- Apply this migration (upgrade)
		require
			database_open: a_database.is_open
		deferred
		end

	down (a_database: SIMPLE_SQL_DATABASE)
			-- Reverse this migration (downgrade)
		require
			database_open: a_database.is_open
		deferred
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
