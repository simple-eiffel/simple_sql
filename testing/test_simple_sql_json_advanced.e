note
	description: "Test advanced JSON support using SQLite JSON1 extension"
	testing: "type/manual"
	testing: "execution/serial"

class
	TEST_SIMPLE_SQL_JSON_ADVANCED

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
			create db.make_memory
			create json_helper.make (db)
		end

	on_clean
			-- Cleanup after each test
		do
			if db.is_open then
				db.close
			end
			Precursor
		end

feature {NONE} -- Test support

	db: SIMPLE_SQL_DATABASE
	json_helper: SIMPLE_SQL_JSON

feature -- Test routines: Validation

	test_json_validation_valid
			-- Test JSON validation with valid JSON
		note
			testing: "covers/{SIMPLE_SQL_JSON}.is_valid_json"
		do
			assert_true ("valid_object", json_helper.is_valid_json ("{%"name%":%"Alice%"}"))
			assert_true ("valid_array", json_helper.is_valid_json ("[1,2,3]"))
			assert_true ("valid_string", json_helper.is_valid_json ("%"hello%""))
			assert_true ("valid_number", json_helper.is_valid_json ("42"))
			assert_true ("valid_bool", json_helper.is_valid_json ("true"))
			assert_true ("valid_null", json_helper.is_valid_json ("null"))
		end

	test_json_validation_invalid
			-- Test JSON validation with invalid JSON
		note
			testing: "covers/{SIMPLE_SQL_JSON}.is_valid_json"
		do
			assert_false ("invalid_missing_quote", json_helper.is_valid_json ("{name:%"Alice%"}"))
			assert_false ("invalid_trailing_comma", json_helper.is_valid_json ("[1,2,]"))
			assert_false ("invalid_unclosed", json_helper.is_valid_json ("{%"name%":%"Alice%""))
		end

feature -- Test routines: Type Checking

	test_json_type_root
			-- Test JSON type detection at root
		note
			testing: "covers/{SIMPLE_SQL_JSON}.json_type"
		local
			l_type: detachable STRING_32
		do
			l_type := json_helper.json_type ("{%"a%":1}", Void)
			assert_true ("object_type_exists", l_type /= Void)
			if l_type /= Void then
				assert_strings_equal ("object_type", "object", l_type)
			end

			l_type := json_helper.json_type ("[1,2,3]", Void)
			assert_true ("array_type_exists", l_type /= Void)
			if l_type /= Void then
				assert_strings_equal ("array_type", "array", l_type)
			end

			l_type := json_helper.json_type ("%"hello%"", Void)
			assert_true ("text_type_exists", l_type /= Void)
			if l_type /= Void then
				assert_strings_equal ("text_type", "text", l_type)
			end

			l_type := json_helper.json_type ("42", Void)
			assert_true ("integer_type_exists", l_type /= Void)
			if l_type /= Void then
				assert_strings_equal ("integer_type", "integer", l_type)
			end

			l_type := json_helper.json_type ("3.14", Void)
			assert_true ("real_type_exists", l_type /= Void)
			if l_type /= Void then
				assert_strings_equal ("real_type", "real", l_type)
			end

			l_type := json_helper.json_type ("true", Void)
			assert_true ("true_type_exists", l_type /= Void)
			if l_type /= Void then
				assert_strings_equal ("true_type", "true", l_type)
			end

			l_type := json_helper.json_type ("false", Void)
			assert_true ("false_type_exists", l_type /= Void)
			if l_type /= Void then
				assert_strings_equal ("false_type", "false", l_type)
			end

			l_type := json_helper.json_type ("null", Void)
			assert_true ("null_type_exists", l_type /= Void)
			if l_type /= Void then
				assert_strings_equal ("null_type", "null", l_type)
			end
		end

	test_json_type_with_path
			-- Test JSON type detection at path
		note
			testing: "covers/{SIMPLE_SQL_JSON}.json_type"
		local
			l_json: STRING_8
			l_type: detachable STRING_32
		do
			l_json := "{%"name%":%"Alice%",%"age%":30,%"active%":true}"

			l_type := json_helper.json_type (l_json, "$.name")
			assert_true ("name_type_exists", l_type /= Void)
			if l_type /= Void then
				assert_strings_equal ("name_is_text", "text", l_type)
			end

			l_type := json_helper.json_type (l_json, "$.age")
			assert_true ("age_type_exists", l_type /= Void)
			if l_type /= Void then
				assert_strings_equal ("age_is_integer", "integer", l_type)
			end

			l_type := json_helper.json_type (l_json, "$.active")
			assert_true ("active_type_exists", l_type /= Void)
			if l_type /= Void then
				assert_strings_equal ("active_is_true", "true", l_type)
			end
		end

feature -- Test routines: Path Extraction

	test_extract_simple_paths
			-- Test extracting values at simple paths
		note
			testing: "covers/{SIMPLE_SQL_JSON}.extract"
		local
			l_json: STRING_8
			l_result: detachable STRING_32
		do
			l_json := "{%"user%":{%"name%":%"Alice%",%"age%":30}}"

			l_result := json_helper.extract (l_json, "$.user.name")
			assert_true ("name_extracted", l_result /= Void)
			if l_result /= Void then
				assert_true ("name_is_alice", l_result.has_substring ("Alice"))
			end

			l_result := json_helper.extract (l_json, "$.user.age")
			assert_true ("age_extracted", l_result /= Void)
			if l_result /= Void then
				assert_true ("age_is_30", l_result.has_substring ("30"))
			end
		end

	test_extract_array_element
			-- Test extracting array elements
		note
			testing: "covers/{SIMPLE_SQL_JSON}.extract"
		local
			l_json: STRING_8
			l_result: detachable STRING_32
		do
			l_json := "{%"colors%":[%"red%",%"green%",%"blue%"]}"

			l_result := json_helper.extract (l_json, "$.colors[0]")
			assert_true ("first_color_extracted", l_result /= Void)
			if l_result /= Void then
				assert_true ("first_is_red", l_result.has_substring ("red"))
			end

			l_result := json_helper.extract (l_json, "$.colors[2]")
			assert_true ("third_color_extracted", l_result /= Void)
			if l_result /= Void then
				assert_true ("third_is_blue", l_result.has_substring ("blue"))
			end
		end

	test_extract_multiple_paths
			-- Test extracting multiple paths at once
		note
			testing: "covers/{SIMPLE_SQL_JSON}.extract_multiple"
		local
			l_json: STRING_8
			l_result: SIMPLE_SQL_RESULT
		do
			l_json := "{%"name%":%"Alice%",%"age%":30,%"city%":%"NYC%"}"
			l_result := json_helper.extract_multiple (l_json, <<"$.name", "$.age", "$.city">>)

			assert_false ("result_not_empty", l_result.is_empty)
			assert_equal ("one_row", 1, l_result.count)
		end

feature -- Test routines: Modification

	test_json_set_new_field
			-- Test setting a new field
		note
			testing: "covers/{SIMPLE_SQL_JSON}.json_set"
		local
			l_json, l_result: STRING_8
		do
			l_json := "{%"a%":1}"
			l_result := json_helper.json_set (l_json, "$.b", 2)
			assert_true ("b_added", l_result.has_substring ("%"b%""))
			assert_true ("b_is_2", l_result.has_substring ("2"))
		end

	test_json_set_existing_field
			-- Test setting an existing field
		note
			testing: "covers/{SIMPLE_SQL_JSON}.json_set"
		local
			l_json, l_result: STRING_8
		do
			l_json := "{%"a%":1}"
			l_result := json_helper.json_set (l_json, "$.a", 99)
			assert_true ("a_updated", l_result.has_substring ("99"))
		end

	test_json_insert_new_field
			-- Test inserting a new field (only if doesn't exist)
		note
			testing: "covers/{SIMPLE_SQL_JSON}.json_insert"
		local
			l_json, l_result: STRING_8
		do
			l_json := "{%"a%":1}"
			l_result := json_helper.json_insert (l_json, "$.b", 2)
			assert_true ("b_inserted", l_result.has_substring ("%"b%""))
		end

	test_json_insert_existing_field
			-- Test inserting into existing field (should not change)
		note
			testing: "covers/{SIMPLE_SQL_JSON}.json_insert"
		local
			l_json, l_result: STRING_8
		do
			l_json := "{%"a%":1}"
			l_result := json_helper.json_insert (l_json, "$.a", 99)
			assert_false ("a_not_changed", l_result.has_substring ("99"))
			assert_true ("a_still_1", l_result.has_substring ("1"))
		end

	test_json_replace_existing_field
			-- Test replacing existing field
		note
			testing: "covers/{SIMPLE_SQL_JSON}.json_replace"
		local
			l_json, l_result: STRING_8
		do
			l_json := "{%"a%":1}"
			l_result := json_helper.json_replace (l_json, "$.a", 99)
			assert_true ("a_replaced", l_result.has_substring ("99"))
		end

	test_json_replace_nonexistent_field
			-- Test replacing nonexistent field (should not change)
		note
			testing: "covers/{SIMPLE_SQL_JSON}.json_replace"
		local
			l_json, l_result: STRING_8
		do
			l_json := "{%"a%":1}"
			l_result := json_helper.json_replace (l_json, "$.b", 2)
			assert_false ("b_not_added", l_result.has_substring ("%"b%""))
		end

	test_json_remove_field
			-- Test removing a field
		note
			testing: "covers/{SIMPLE_SQL_JSON}.json_remove"
		local
			l_json, l_result: STRING_8
		do
			l_json := "{%"a%":1,%"b%":2}"
			l_result := json_helper.json_remove (l_json, "$.b")
			assert_false ("b_removed", l_result.has_substring ("%"b%""))
			assert_true ("a_still_there", l_result.has_substring ("%"a%""))
		end

feature -- Test routines: Creation

	test_json_array_creation
			-- Test creating JSON array from values
		note
			testing: "covers/{SIMPLE_SQL_JSON}.json_array_from_values"
		local
			l_array: STRING_8
		do
			l_array := json_helper.json_array_from_values (<<1, "two", 3.0>>)
			assert_true ("has_1", l_array.has_substring ("1"))
			assert_true ("has_two", l_array.has_substring ("two"))
			assert_true ("has_3", l_array.has_substring ("3"))
		end

	test_json_object_creation
			-- Test creating JSON object from key-value pairs
		note
			testing: "covers/{SIMPLE_SQL_JSON}.json_object_from_pairs"
		local
			l_object: STRING_8
		do
			l_object := json_helper.json_object_from_pairs (<<["name", "Alice"], ["age", 30]>>)
			assert_true ("has_name", l_object.has_substring ("%"name%""))
			assert_true ("has_alice", l_object.has_substring ("Alice"))
			assert_true ("has_age", l_object.has_substring ("%"age%""))
			assert_true ("has_30", l_object.has_substring ("30"))
		end

feature -- Test routines: Aggregation

	test_aggregate_to_array
			-- Test aggregating column values to JSON array
		note
			testing: "covers/{SIMPLE_SQL_JSON}.aggregate_to_array"
		local
			l_array: STRING_8
		do
			db.execute ("CREATE TABLE users (name TEXT)")
			db.execute ("INSERT INTO users VALUES ('Alice')")
			db.execute ("INSERT INTO users VALUES ('Bob')")
			db.execute ("INSERT INTO users VALUES ('Charlie')")

			l_array := json_helper.aggregate_to_array ("users", "name", Void)
			assert_true ("has_alice", l_array.has_substring ("Alice"))
			assert_true ("has_bob", l_array.has_substring ("Bob"))
			assert_true ("has_charlie", l_array.has_substring ("Charlie"))
		end

	test_aggregate_to_array_with_where
			-- Test aggregating with WHERE clause
		note
			testing: "covers/{SIMPLE_SQL_JSON}.aggregate_to_array"
		local
			l_array: STRING_8
		do
			db.execute ("CREATE TABLE users (name TEXT, age INTEGER)")
			db.execute ("INSERT INTO users VALUES ('Alice', 30)")
			db.execute ("INSERT INTO users VALUES ('Bob', 17)")
			db.execute ("INSERT INTO users VALUES ('Charlie', 25)")

			l_array := json_helper.aggregate_to_array ("users", "name", "age >= 18")
			assert_true ("has_alice", l_array.has_substring ("Alice"))
			assert_false ("no_bob", l_array.has_substring ("Bob"))
			assert_true ("has_charlie", l_array.has_substring ("Charlie"))
		end

	test_aggregate_to_object
			-- Test aggregating key-value pairs to JSON object
		note
			testing: "covers/{SIMPLE_SQL_JSON}.aggregate_to_object"
		local
			l_object: STRING_8
		do
			db.execute ("CREATE TABLE settings (key TEXT, value TEXT)")
			db.execute ("INSERT INTO settings VALUES ('theme', 'dark')")
			db.execute ("INSERT INTO settings VALUES ('language', 'en')")
			db.execute ("INSERT INTO settings VALUES ('notifications', 'on')")

			l_object := json_helper.aggregate_to_object ("settings", "key", "value", Void)
			assert_true ("has_theme", l_object.has_substring ("%"theme%""))
			assert_true ("has_dark", l_object.has_substring ("dark"))
			assert_true ("has_language", l_object.has_substring ("%"language%""))
			assert_true ("has_en", l_object.has_substring ("en"))
		end

feature -- Test routines: Integration

	test_json_in_table_queries
			-- Test querying JSON stored in table
		note
			testing: "integration"
		local
			l_result: SIMPLE_SQL_RESULT
			l_name: detachable STRING_32
		do
			-- Store JSON in table
			db.execute ("CREATE TABLE documents (data TEXT)")
			db.execute ("INSERT INTO documents VALUES ('{%"user%":{%"name%":%"Alice%",%"age%":30}}')")

			-- Query using JSON path
			l_result := db.query ("SELECT json_extract(data, '$.user.name') as name FROM documents")
			assert_false ("result_not_empty", l_result.is_empty)

			l_name := l_result.first.string_value ("name")
			assert_true ("name_extracted", l_name.has_substring ("Alice"))
		end

	test_json_modification_in_update
			-- Test modifying JSON in UPDATE statement
		note
			testing: "integration"
		local
			l_result: SIMPLE_SQL_RESULT
		do
			-- Create table with JSON
			db.execute ("CREATE TABLE config (id INTEGER, data TEXT)")
			db.execute ("INSERT INTO config VALUES (1, '{%"theme%":%"light%"}')")

			-- Update JSON using json_set
			db.execute ("UPDATE config SET data = json_set(data, '$.theme', 'dark') WHERE id = 1")

			-- Verify
			l_result := db.query ("SELECT json_extract(data, '$.theme') as theme FROM config WHERE id = 1")
			assert_false ("result_not_empty", l_result.is_empty)
			assert_true ("theme_is_dark", l_result.first.string_value ("theme").has_substring ("dark"))
		end

end
