note
	description: "Test migration 1 - Create users table"

class
	TEST_MIGRATION_001

inherit
	SIMPLE_SQL_MIGRATION

feature -- Access

	version: INTEGER = 1

	description: STRING_8 = "Create users table"

feature -- Operations

	up (a_database: SIMPLE_SQL_DATABASE)
		do
			a_database.execute ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
		end

	down (a_database: SIMPLE_SQL_DATABASE)
		do
			a_database.execute ("DROP TABLE users")
		end

end
