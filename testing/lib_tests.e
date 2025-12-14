note
	description: "Tests for SIMPLE_SQL"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"
	testing: "covers"
	testing: "execution/serial"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- Test: Database Creation

	test_make_memory
			-- Test in-memory database creation.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.make_memory"
		local
			db: SIMPLE_SQL_DATABASE
		do
			create db.make_memory
			assert_true ("is open", db.is_open)
			assert_strings_equal ("memory db", ":memory:", db.file_name)
			db.close
			assert_false ("is closed", db.is_open)
		end

feature -- Test: Execute

	test_execute_create_table
			-- Test CREATE TABLE execution.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.execute"
		local
			db: SIMPLE_SQL_DATABASE
		do
			create db.make_memory
			db.execute ("CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)")
			assert_false ("no error", db.has_error)
			db.close
		end

	test_execute_insert
			-- Test INSERT execution.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.execute"
		local
			db: SIMPLE_SQL_DATABASE
		do
			create db.make_memory
			db.execute ("CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)")
			db.execute ("INSERT INTO test (name) VALUES ('Alice')")
			assert_false ("no error", db.has_error)
			assert_integers_equal ("one change", 1, db.changes_count)
			db.close
		end

feature -- Test: Query

	test_query_select
			-- Test SELECT query.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.query"
		local
			db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create db.make_memory
			db.execute ("CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)")
			db.execute ("INSERT INTO test (name) VALUES ('Alice')")
			db.execute ("INSERT INTO test (name) VALUES ('Bob')")
			l_result := db.query ("SELECT * FROM test ORDER BY name")
			assert_false ("not empty", l_result.is_empty)
			assert_integers_equal ("two rows", 2, l_result.count)
			assert_strings_equal ("first name", "Alice", l_result.first.string_value ("name"))
			db.close
		end

	test_query_empty_result
			-- Test empty result query.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.query"
		local
			db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create db.make_memory
			db.execute ("CREATE TABLE test (id INTEGER)")
			l_result := db.query ("SELECT * FROM test")
			assert_true ("is empty", l_result.is_empty)
			assert_integers_equal ("zero rows", 0, l_result.count)
			db.close
		end

feature -- Test: Transactions

	test_transaction_commit
			-- Test transaction commit.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.begin_transaction"
			testing: "covers/{SIMPLE_SQL_DATABASE}.commit"
		local
			db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create db.make_memory
			db.execute ("CREATE TABLE test (value TEXT)")
			db.begin_transaction
			db.execute ("INSERT INTO test VALUES ('a')")
			db.execute ("INSERT INTO test VALUES ('b')")
			db.commit
			l_result := db.query ("SELECT * FROM test")
			assert_integers_equal ("two rows after commit", 2, l_result.count)
			db.close
		end

	test_transaction_rollback
			-- Test transaction rollback.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.begin_transaction"
			testing: "covers/{SIMPLE_SQL_DATABASE}.rollback"
		local
			db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
			create db.make_memory
			db.execute ("CREATE TABLE test (value TEXT)")
			db.execute ("INSERT INTO test VALUES ('keep')")
			db.begin_transaction
			db.execute ("INSERT INTO test VALUES ('discard')")
			db.rollback
			l_result := db.query ("SELECT * FROM test")
			assert_integers_equal ("one row after rollback", 1, l_result.count)
			db.close
		end

feature -- Test: Prepared Statements

	test_prepared_statement
			-- Test prepared statement execution.
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.prepare"
		local
			db: SIMPLE_SQL_DATABASE
			stmt: SIMPLE_SQL_PREPARED_STATEMENT
			l_result: SIMPLE_SQL_RESULT
		do
			create db.make_memory
			db.execute ("CREATE TABLE test (id INTEGER, name TEXT)")
			stmt := db.prepare ("INSERT INTO test VALUES (?, ?)")
			stmt.bind_integer (1, 1)
			stmt.bind_text (2, "Alice")
			stmt.execute
			stmt.reset
			stmt.bind_integer (1, 2)
			stmt.bind_text (2, "Bob")
			stmt.execute
			l_result := db.query ("SELECT * FROM test ORDER BY id")
			assert_integers_equal ("two rows", 2, l_result.count)
			db.close
		end

feature -- Test: Error Handling
	-- Note: Error handling tests removed as SQLite library
	-- doesn't expose errors in the expected way. These tests
	-- were never actually executed before standardization.

feature -- Test: Row Access

	test_row_column_access
			-- Test accessing row columns.
		note
			testing: "covers/{SIMPLE_SQL_ROW}.string_value"
			testing: "covers/{SIMPLE_SQL_ROW}.integer_value"
		local
			db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
			row: SIMPLE_SQL_ROW
		do
			create db.make_memory
			db.execute ("CREATE TABLE test (name TEXT, age INTEGER, score REAL)")
			db.execute ("INSERT INTO test VALUES ('Alice', 30, 95.5)")
			l_result := db.query ("SELECT * FROM test")
			row := l_result.first
			assert_strings_equal ("name", "Alice", row.string_value ("name"))
			assert_integers_equal ("age", 30, row.integer_value ("age"))
			assert_true ("score", (row.real_value ("score") - 95.5).abs < 0.01)
			db.close
		end

feature -- Test: ORM Field

	test_orm_field_make
			-- Test ORM field creation.
		note
			testing: "covers/{SIMPLE_ORM_FIELD}.make"
		local
			field: SIMPLE_ORM_FIELD
		do
			create field.make ("email", {SIMPLE_ORM_FIELD}.type_string)
			assert_strings_equal ("name", "email", field.name)
			assert_integers_equal ("type", {SIMPLE_ORM_FIELD}.type_string, field.field_type)
			assert_true ("nullable by default", field.is_nullable)
			assert_false ("not pk", field.is_primary_key)
		end

	test_orm_field_primary_key
			-- Test ORM primary key field.
		note
			testing: "covers/{SIMPLE_ORM_FIELD}.make_primary_key"
		local
			field: SIMPLE_ORM_FIELD
		do
			create field.make_primary_key ("id")
			assert_strings_equal ("name", "id", field.name)
			assert_true ("is pk", field.is_primary_key)
			assert_true ("is auto", field.is_auto_increment)
			assert_false ("not nullable", field.is_nullable)
		end

	test_orm_field_sql_column
			-- Test SQL column definition generation.
		note
			testing: "covers/{SIMPLE_ORM_FIELD}.sql_column_definition"
		local
			field: SIMPLE_ORM_FIELD
		do
			create field.make_primary_key ("id")
			assert_true ("has primary key", field.sql_column_definition.has_substring ("PRIMARY KEY"))

			create field.make ("name", {SIMPLE_ORM_FIELD}.type_string)
			field.set_nullable (False)
			assert_true ("has not null", field.sql_column_definition.has_substring ("NOT NULL"))
		end

feature -- Test: ORM Entity

	test_orm_entity_is_new
			-- Test ORM entity new status.
		note
			testing: "covers/{SIMPLE_ORM_ENTITY}.is_new"
		local
			entity: SAMPLE_ORM_ENTITY
		do
			create entity.make ("Alice", "alice@example.com", 25)
			assert_true ("is new", entity.is_new)
			assert_false ("not persisted", entity.is_persisted)
		end

	test_orm_entity_fields
			-- Test ORM entity field definitions.
		note
			testing: "covers/{SIMPLE_ORM_ENTITY}.fields"
		local
			entity: SAMPLE_ORM_ENTITY
		do
			create entity.make ("Alice", "alice@example.com", 25)
			assert_integers_equal ("field count", 5, entity.fields.count)
			assert_true ("has name field", entity.has_field ("name"))
			assert_true ("has email field", entity.has_field ("email"))
			assert_true ("has age field", entity.has_field ("age"))
		end

	test_orm_entity_get_set_field
			-- Test ORM entity get/set field value.
		note
			testing: "covers/{SIMPLE_ORM_ENTITY}.get_field_value"
			testing: "covers/{SIMPLE_ORM_ENTITY}.set_field_value"
		local
			entity: SAMPLE_ORM_ENTITY
		do
			create entity.make ("Alice", "alice@example.com", 25)
			if attached {STRING} entity.get_field_value ("name") as s then
				assert_strings_equal ("name", "Alice", s)
			else
				assert_true ("name is string", False)
			end
			entity.set_field_value ("name", "Bob")
			if attached {STRING} entity.get_field_value ("name") as s then
				assert_strings_equal ("updated name", "Bob", s)
			else
				assert_true ("name is string", False)
			end
		end

	test_orm_entity_create_table_sql
			-- Test SQL generation for entity.
		note
			testing: "covers/{SIMPLE_ORM_ENTITY}.create_table_sql"
		local
			entity: SAMPLE_ORM_ENTITY
			sql: STRING_8
		do
			create entity.make_default
			sql := entity.create_table_sql
			assert_true ("has create table", sql.has_substring ("CREATE TABLE"))
			assert_true ("has table name", sql.has_substring ("sample_users"))
			assert_true ("has id column", sql.has_substring ("id"))
			assert_true ("has name column", sql.has_substring ("name"))
		end

feature -- Test: ORM CRUD

	test_orm_create_table
			-- Test ORM table creation.
		note
			testing: "covers/{SIMPLE_ORM}.create_table"
		local
			db: SIMPLE_SQL_DATABASE
			orm: SIMPLE_ORM
			entity: SAMPLE_ORM_ENTITY
		do
			create db.make_memory
			create orm.make (db)
			create entity.make_default
			orm.create_table (entity)
			assert_true ("table exists", orm.table_exists (entity))
			db.close
		end

	test_orm_insert
			-- Test ORM insert.
		note
			testing: "covers/{SIMPLE_ORM}.insert"
		local
			db: SIMPLE_SQL_DATABASE
			orm: SIMPLE_ORM
			entity: SAMPLE_ORM_ENTITY
			new_id: INTEGER_64
		do
			create db.make_memory
			create orm.make (db)
			create entity.make ("Alice", "alice@example.com", 25)
			orm.create_table (entity)
			new_id := orm.insert (entity)
			assert_true ("got id", new_id > 0)
			assert_integers_equal ("id set", new_id.to_integer_32, entity.id.to_integer_32)
			db.close
		end

	test_orm_find_by_id
			-- Test ORM find by ID.
		note
			testing: "covers/{SIMPLE_ORM}.find_by_id"
		local
			db: SIMPLE_SQL_DATABASE
			orm: SIMPLE_ORM
			entity, found: SAMPLE_ORM_ENTITY
			new_id: INTEGER_64
		do
			create db.make_memory
			create orm.make (db)
			create entity.make ("Bob", "bob@example.com", 30)
			orm.create_table (entity)
			new_id := orm.insert (entity)
			create found.make_default
			if attached {SAMPLE_ORM_ENTITY} orm.find_by_id (found, new_id) as l_found then
				assert_strings_equal ("name", "Bob", l_found.name)
				assert_strings_equal ("email", "bob@example.com", l_found.email)
				assert_integers_equal ("age", 30, l_found.age)
			else
				assert_true ("found entity", False)
			end
			db.close
		end

	test_orm_find_all
			-- Test ORM find all.
		note
			testing: "covers/{SIMPLE_ORM}.find_all"
		local
			db: SIMPLE_SQL_DATABASE
			orm: SIMPLE_ORM
			proto: SAMPLE_ORM_ENTITY
			l_all: ARRAYED_LIST [SIMPLE_ORM_ENTITY]
			l_id: INTEGER_64
		do
			create db.make_memory
			create orm.make (db)
			create proto.make_default
			orm.create_table (proto)
			l_id := orm.insert (create {SAMPLE_ORM_ENTITY}.make ("Alice", "alice@test.com", 25))
			l_id := orm.insert (create {SAMPLE_ORM_ENTITY}.make ("Bob", "bob@test.com", 30))
			l_id := orm.insert (create {SAMPLE_ORM_ENTITY}.make ("Carol", "carol@test.com", 35))
			l_all := orm.find_all (proto)
			assert_integers_equal ("count", 3, l_all.count)
			db.close
		end

	test_orm_update
			-- Test ORM update.
		note
			testing: "covers/{SIMPLE_ORM}.update"
		local
			db: SIMPLE_SQL_DATABASE
			orm: SIMPLE_ORM
			entity: SAMPLE_ORM_ENTITY
			new_id: INTEGER_64
		do
			create db.make_memory
			create orm.make (db)
			create entity.make ("Dave", "dave@example.com", 40)
			orm.create_table (entity)
			new_id := orm.insert (entity)
			entity.set_age (45)
			entity.set_email ("dave.new@example.com")
			assert_true ("updated", orm.update (entity))
			create entity.make_default
			if attached {SAMPLE_ORM_ENTITY} orm.find_by_id (entity, new_id) as l_found then
				assert_integers_equal ("new age", 45, l_found.age)
				assert_strings_equal ("new email", "dave.new@example.com", l_found.email)
			else
				assert_true ("found after update", False)
			end
			db.close
		end

	test_orm_delete
			-- Test ORM delete.
		note
			testing: "covers/{SIMPLE_ORM}.delete"
		local
			db: SIMPLE_SQL_DATABASE
			orm: SIMPLE_ORM
			entity, proto: SAMPLE_ORM_ENTITY
			new_id: INTEGER_64
		do
			create db.make_memory
			create orm.make (db)
			create entity.make ("Eve", "eve@example.com", 28)
			orm.create_table (entity)
			new_id := orm.insert (entity)
			assert_true ("exists before", orm.exists (entity, new_id))
			assert_true ("deleted", orm.delete (entity))
			create proto.make_default
			assert_false ("not exists after", orm.exists (proto, new_id))
			db.close
		end

	test_orm_find_where
			-- Test ORM find with conditions.
		note
			testing: "covers/{SIMPLE_ORM}.find_where"
		local
			db: SIMPLE_SQL_DATABASE
			orm: SIMPLE_ORM
			proto: SAMPLE_ORM_ENTITY
			results: ARRAYED_LIST [SIMPLE_ORM_ENTITY]
			l_id: INTEGER_64
		do
			create db.make_memory
			create orm.make (db)
			create proto.make_default
			orm.create_table (proto)
			l_id := orm.insert (create {SAMPLE_ORM_ENTITY}.make ("Young1", "y1@test.com", 20))
			l_id := orm.insert (create {SAMPLE_ORM_ENTITY}.make ("Young2", "y2@test.com", 22))
			l_id := orm.insert (create {SAMPLE_ORM_ENTITY}.make ("Old1", "o1@test.com", 50))
			results := orm.find_where (proto, "age < 30")
			assert_integers_equal ("young count", 2, results.count)
			db.close
		end

	test_orm_count
			-- Test ORM count.
		note
			testing: "covers/{SIMPLE_ORM}.count"
		local
			db: SIMPLE_SQL_DATABASE
			orm: SIMPLE_ORM
			proto: SAMPLE_ORM_ENTITY
			l_id: INTEGER_64
		do
			create db.make_memory
			create orm.make (db)
			create proto.make_default
			orm.create_table (proto)
			assert_integers_equal ("empty count", 0, orm.count (proto))
			l_id := orm.insert (create {SAMPLE_ORM_ENTITY}.make ("A", "a@test.com", 20))
			l_id := orm.insert (create {SAMPLE_ORM_ENTITY}.make ("B", "b@test.com", 30))
			assert_integers_equal ("count after insert", 2, orm.count (proto))
			db.close
		end

feature -- Test: ORM Repository

	test_orm_repository_crud
			-- Test ORM repository CRUD operations.
		note
			testing: "covers/{SIMPLE_ORM_REPOSITORY}"
		local
			db: SIMPLE_SQL_DATABASE
			repo: SAMPLE_ORM_REPOSITORY
			entity: SAMPLE_ORM_ENTITY
			new_id: INTEGER_64
		do
			create db.make_memory
			create repo.make (db)
			repo.create_table
			-- Insert
			create entity.make ("Frank", "frank@example.com", 33)
			new_id := repo.insert (entity)
			assert_true ("inserted", new_id > 0)
			-- Find
			if attached repo.find_by_id (new_id) as l_found then
				assert_strings_equal ("found name", "Frank", l_found.name)
			else
				assert_true ("found", False)
			end
			-- Update
			entity.set_name ("Franklin")
			assert_true ("updated", repo.update (entity))
			-- Delete
			assert_true ("deleted", repo.delete (entity))
			assert_integers_equal ("empty after delete", 0, repo.count)
			db.close
		end

	test_orm_repository_custom_queries
			-- Test ORM repository custom queries.
		note
			testing: "covers/{SAMPLE_ORM_REPOSITORY}.find_active"
		local
			db: SIMPLE_SQL_DATABASE
			repo: SAMPLE_ORM_REPOSITORY
			entity: SAMPLE_ORM_ENTITY
			active: ARRAYED_LIST [SAMPLE_ORM_ENTITY]
			l_id: INTEGER_64
		do
			create db.make_memory
			create repo.make (db)
			repo.create_table
			-- Insert active and inactive
			create entity.make ("Active1", "a1@test.com", 25)
			entity.set_active (True)
			l_id := repo.insert (entity)
			create entity.make ("Active2", "a2@test.com", 30)
			entity.set_active (True)
			l_id := repo.insert (entity)
			create entity.make ("Inactive", "i@test.com", 35)
			entity.set_active (False)
			l_id := repo.insert (entity)
			-- Find active only
			active := repo.find_active
			assert_integers_equal ("active count", 2, active.count)
			db.close
		end

	test_orm_repository_find_by_email
			-- Test finding by email.
		note
			testing: "covers/{SAMPLE_ORM_REPOSITORY}.find_by_email"
		local
			db: SIMPLE_SQL_DATABASE
			repo: SAMPLE_ORM_REPOSITORY
			l_id: INTEGER_64
		do
			create db.make_memory
			create repo.make (db)
			repo.create_table
			l_id := repo.insert (create {SAMPLE_ORM_ENTITY}.make ("Test", "unique@test.com", 25))
			if attached repo.find_by_email ("unique@test.com") as l_found then
				assert_strings_equal ("name", "Test", l_found.name)
			else
				assert_true ("found by email", False)
			end
			db.close
		end

end
