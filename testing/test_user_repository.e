note
	description: "Test repository for USER_ENTITY - demonstrates repository pattern usage"

class
	TEST_USER_REPOSITORY

inherit
	SIMPLE_SQL_REPOSITORY [TEST_USER_ENTITY]

create
	make

feature -- Access

	table_name: STRING_8 = "users"
			-- <Precursor>

	primary_key_column: STRING_8 = "id"
			-- <Precursor>

feature -- Test Setup

	create_table
			-- Create the users table for testing
		do
			database.execute ("[
				CREATE TABLE users (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					name TEXT NOT NULL,
					age INTEGER NOT NULL,
					status TEXT NOT NULL DEFAULT 'active'
				)
			]")
		end

	seed_data
			-- Insert test data
		do
			database.execute ("INSERT INTO users (name, age, status) VALUES ('Alice', 30, 'active')")
			database.execute ("INSERT INTO users (name, age, status) VALUES ('Bob', 25, 'inactive')")
			database.execute ("INSERT INTO users (name, age, status) VALUES ('Charlie', 35, 'active')")
		end

feature {NONE} -- Implementation

	row_to_entity (a_row: SIMPLE_SQL_ROW): TEST_USER_ENTITY
			-- <Precursor>
		do
			create Result.make (
				a_row.integer_value ("id").to_integer_64,
				a_row.string_value ("name").to_string_8,
				a_row.integer_value ("age"),
				a_row.string_value ("status").to_string_8
			)
		end

	entity_to_columns (a_entity: TEST_USER_ENTITY): HASH_TABLE [detachable ANY, STRING_8]
			-- <Precursor>
		do
			create Result.make (4)
			-- Note: Don't include 'id' since it's AUTOINCREMENT
			Result.put (a_entity.name, "name")
			Result.put (a_entity.age, "age")
			Result.put (a_entity.status, "status")
		end

	entity_id (a_entity: TEST_USER_ENTITY): INTEGER_64
			-- <Precursor>
		do
			Result := a_entity.id
		end

end
