note
	description: "Test JSON storage using SIMPLE_JSON library"
	testing: "type/manual"
	testing: "execution/serial"

class
	TEST_SIMPLE_SQL_JSON

inherit
	TEST_SET_BASE
		redefine
			on_prepare,
			on_clean
		end

feature {NONE} -- Events

	on_prepare
			-- Setup before each test
		do
			Precursor
			create test_db.make_memory
		end

	on_clean
			-- Cleanup after each test
		do
			if test_db.is_open then
				test_db.close
			end
			Precursor
		end

feature -- Test routines

	test_store_and_retrieve_json_object
			-- Test storing SIMPLE_JSON_OBJECT as TEXT
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.execute"
		local
			l_json: SIMPLE_JSON
			l_obj: SIMPLE_JSON_OBJECT
			l_result: SIMPLE_SQL_RESULT
			l_value: detachable SIMPLE_JSON_VALUE
			l_retrieved: SIMPLE_JSON_OBJECT
		do
			create l_json

			-- Create JSON object
			create l_obj.make
			l_obj.put_string ("Alice", "name").do_nothing
			l_obj.put_integer (30, "age").do_nothing

			-- Store
			test_db.execute ("CREATE TABLE users (id INTEGER, data TEXT)")
			test_db.execute ("INSERT INTO users VALUES (1, '" + l_obj.to_json_string + "')")

			-- Retrieve and parse
			l_result := test_db.query ("SELECT data FROM users WHERE id=1")
			l_value := l_json.parse (l_result.first.string_value ("data"))
			check attached l_value as al_value then
				l_retrieved := al_value.as_object
			end

			if attached l_retrieved.item ("name") as al_name then
				assert_strings_equal ("name", "Alice", al_name.as_string_32)
			end
			if attached l_retrieved.item ("age") as al_age then
				assert_integers_equal ("age", 30, al_age.as_integer.to_integer)
			end
		end

	test_json_array_storage
			-- Test storing JSON array
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.execute"
		local
			l_json: SIMPLE_JSON
			l_array: SIMPLE_JSON_ARRAY
			l_result: SIMPLE_SQL_RESULT
			l_value: detachable SIMPLE_JSON_VALUE
			l_retrieved: SIMPLE_JSON_ARRAY
		do
			create l_json

			-- Create array
			create l_array.make
			l_array.add_string ("red").do_nothing
			l_array.add_string ("green").do_nothing
			l_array.add_string ("blue").do_nothing

			-- Store
			test_db.execute ("CREATE TABLE colors (data TEXT)")
			test_db.execute ("INSERT INTO colors VALUES ('" + l_array.to_json_string + "')")

			-- Retrieve and parse
			l_result := test_db.query ("SELECT data FROM colors")
			l_value := l_json.parse (l_result.first.string_value ("data"))
			check attached l_value as al_value then
				l_retrieved := al_value.as_array
			end

			assert_equal ("count", 3, l_retrieved.count)
			assert_strings_equal ("first", "red", l_retrieved.item (1).as_string_32)
		end

	test_nested_json_structure
			-- Test nested objects
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.execute"
		local
			l_json: SIMPLE_JSON
			l_obj, l_nested: SIMPLE_JSON_OBJECT
			l_result: SIMPLE_SQL_RESULT
			l_value: detachable SIMPLE_JSON_VALUE
			l_retrieved: SIMPLE_JSON_OBJECT
		do
			create l_json

			-- Create nested structure
			create l_obj.make
			create l_nested.make
			l_nested.put_string ("charlie@test.com", "email").do_nothing
			l_obj.put_string ("Charlie", "name").do_nothing
			l_obj.put_object (l_nested, "contact").do_nothing

			-- Store
			test_db.execute ("CREATE TABLE profiles (data TEXT)")
			test_db.execute ("INSERT INTO profiles VALUES ('" + l_obj.to_json_string + "')")

			-- Retrieve and parse
			l_result := test_db.query ("SELECT data FROM profiles")
			l_value := l_json.parse (l_result.first.string_value ("data"))
			check attached l_value as al_value then
				l_retrieved := al_value.as_object
			end

			if attached l_retrieved.item ("contact") as al_contact then
				if attached al_contact.as_object.item ("email") as al_email then
					assert_strings_equal ("email", "charlie@test.com", al_email.as_string_32)
				end
			end
		end

	test_json_with_null_values
			-- Test NULL handling in JSON
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.execute"
		local
			l_json: SIMPLE_JSON
			l_obj: SIMPLE_JSON_OBJECT
			l_result: SIMPLE_SQL_RESULT
			l_value: detachable SIMPLE_JSON_VALUE
			l_retrieved: SIMPLE_JSON_OBJECT
		do
			create l_json

			create l_obj.make
			l_obj.put_string ("Test", "name").do_nothing
			l_obj.put_null ("optional").do_nothing

			test_db.execute ("CREATE TABLE nulls (data TEXT)")
			test_db.execute ("INSERT INTO nulls VALUES ('" + l_obj.to_json_string + "')")

			l_result := test_db.query ("SELECT data FROM nulls")
			l_value := l_json.parse (l_result.first.string_value ("data"))
			check attached l_value as al_value then
				l_retrieved := al_value.as_object
			end

			if attached l_retrieved.item ("optional") as al_optional then
				assert_true ("has_null", al_optional.is_null)
			end
		end

	test_multiple_json_documents
			-- Test multiple JSON docs in table
		note
			testing: "covers/{SIMPLE_SQL_DATABASE}.execute"
		local
			l_obj1, l_obj2: SIMPLE_JSON_OBJECT
			l_result: SIMPLE_SQL_RESULT
		do
			create l_obj1.make
			l_obj1.put_integer (1, "id").do_nothing
			l_obj1.put_string ("A", "type").do_nothing

			create l_obj2.make
			l_obj2.put_integer (2, "id").do_nothing
			l_obj2.put_string ("B", "type").do_nothing

			test_db.execute ("CREATE TABLE docs (data TEXT)")
			test_db.execute ("INSERT INTO docs VALUES ('" + l_obj1.to_json_string + "')")
			test_db.execute ("INSERT INTO docs VALUES ('" + l_obj2.to_json_string + "')")

			l_result := test_db.query ("SELECT COUNT(*) as cnt FROM docs")
			assert_equal ("two_docs", 2, l_result.first.integer_value ("cnt"))
		end

feature {NONE} -- Implementation

	test_db: SIMPLE_SQL_DATABASE
			-- Test database (in-memory)

;note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_SQL - High-level SQLite API for Eiffel
		Uses SIMPLE_JSON for JSON serialization/deserialization
	]"

end
