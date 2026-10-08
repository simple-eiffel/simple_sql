note
	description: "Migration v1 whose middle statement fails, last succeeds (duplicate key); same SQL as the ADJ-p-atomic probe."

class
	TEST_MIGRATION_MID_FAIL

inherit
	SIMPLE_SQL_MIGRATION

feature -- Access

	version: INTEGER = 1

	description: STRING_8
		do
			Result := "middle statement fails, last succeeds"
		end

feature -- Operations

	up (a_database: SIMPLE_SQL_DATABASE)
		do
			a_database.execute ("CREATE TABLE m1 (id INTEGER PRIMARY KEY)")
			a_database.execute ("INSERT INTO m1 (id) VALUES (1)")
			a_database.execute ("INSERT INTO m1 (id) VALUES (1)")
			a_database.execute ("CREATE TABLE m2 (x INTEGER)")
		end

	down (a_database: SIMPLE_SQL_DATABASE)
		do
			a_database.execute ("DROP TABLE IF EXISTS m2")
			a_database.execute ("DROP TABLE IF EXISTS m1")
		end

end
