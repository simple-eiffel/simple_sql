note
	description: "Base class for database migrations"
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

end
