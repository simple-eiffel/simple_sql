note
	description: "Test migration 3 - Add email to users"

class
	TEST_MIGRATION_003

inherit
	SIMPLE_SQL_MIGRATION

feature -- Access

	version: INTEGER = 3

	description: STRING_8 = "Add email to users"

feature -- Operations

	up (a_database: SIMPLE_SQL_DATABASE)
		do
			a_database.execute ("ALTER TABLE users ADD COLUMN email TEXT")
		end

	down (a_database: SIMPLE_SQL_DATABASE)
		do
			-- SQLite doesn't support DROP COLUMN easily, recreate table
			a_database.execute ("CREATE TABLE users_new (id INTEGER PRIMARY KEY, name TEXT)")
			a_database.execute ("INSERT INTO users_new SELECT id, name FROM users")
			a_database.execute ("DROP TABLE users")
			a_database.execute ("ALTER TABLE users_new RENAME TO users")
		end

end
