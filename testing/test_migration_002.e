note
	description: "Test migration 2 - Create posts table"

class
	TEST_MIGRATION_002

inherit
	SIMPLE_SQL_MIGRATION

feature -- Access

	version: INTEGER = 2

	description: STRING_8 = "Create posts table"

feature -- Operations

	up (a_database: SIMPLE_SQL_DATABASE)
		do
			a_database.execute ("CREATE TABLE posts (id INTEGER PRIMARY KEY, user_id INTEGER, title TEXT)")
		end

	down (a_database: SIMPLE_SQL_DATABASE)
		do
			a_database.execute ("DROP TABLE posts")
		end

end
