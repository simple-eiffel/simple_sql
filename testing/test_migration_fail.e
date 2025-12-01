note
	description: "Test migration that fails - for testing partial failure scenarios"

class
	TEST_MIGRATION_FAIL

inherit
	SIMPLE_SQL_MIGRATION

feature -- Access

	version: INTEGER = 99

	description: STRING_8 = "Failing migration for testing"

feature -- Operations

	up (a_database: SIMPLE_SQL_DATABASE)
		do
			-- This will fail because the table doesn't exist
			a_database.execute ("INSERT INTO nonexistent_table VALUES (1)")
		end

	down (a_database: SIMPLE_SQL_DATABASE)
		do
			-- Nothing to undo
		end

end
