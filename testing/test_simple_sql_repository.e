note
	description: "Test repository pattern implementation"
	testing: "type/manual"
	testing: "execution/isolated"

class
	TEST_SIMPLE_SQL_REPOSITORY

inherit
	TEST_SET_BASE

feature -- Test routines: Find All

	test_find_all_empty
			-- Test find_all on empty table
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.find_all"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
			l_users: ARRAYED_LIST [TEST_USER_ENTITY]
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table

			l_users := l_repo.find_all
			assert_true ("empty_list", l_users.is_empty)

			l_db.close
		end

	test_find_all_with_data
			-- Test find_all returns all records
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.find_all"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
			l_users: ARRAYED_LIST [TEST_USER_ENTITY]
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table
			l_repo.seed_data

			l_users := l_repo.find_all
			assert_equal ("three_users", 3, l_users.count)

			l_db.close
		end

	test_find_all_ordered
			-- Test find_all_ordered returns sorted results
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.find_all_ordered"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
			l_users: ARRAYED_LIST [TEST_USER_ENTITY]
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table
			l_repo.seed_data

			l_users := l_repo.find_all_ordered ("name ASC")
			assert_equal ("three_users", 3, l_users.count)
			assert_strings_equal ("first_alphabetically", "Alice", l_users.first.name)
			assert_strings_equal ("last_alphabetically", "Charlie", l_users.last.name)

			l_db.close
		end

	test_find_all_limited
			-- Test pagination with limit and offset
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.find_all_limited"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
			l_users: ARRAYED_LIST [TEST_USER_ENTITY]
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table
			l_repo.seed_data

			-- Get first 2
			l_users := l_repo.find_all_limited (2, 0)
			assert_equal ("limit_two", 2, l_users.count)

			-- Get with offset
			l_users := l_repo.find_all_limited (2, 1)
			assert_equal ("offset_result", 2, l_users.count)

			l_db.close
		end

feature -- Test routines: Find By ID

	test_find_by_id_exists
			-- Test find_by_id for existing record
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.find_by_id"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
			l_user: detachable TEST_USER_ENTITY
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table
			l_repo.seed_data

			l_user := l_repo.find_by_id (1)
			assert_true ("user_found", attached l_user)
			if attached l_user as u then
				assert_strings_equal ("correct_name", "Alice", u.name)
				assert_equal ("correct_age", 30, u.age)
			end

			l_db.close
		end

	test_find_by_id_not_exists
			-- Test find_by_id for non-existing record
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.find_by_id"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
			l_user: detachable TEST_USER_ENTITY
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table
			l_repo.seed_data

			l_user := l_repo.find_by_id (999)
			assert_true ("user_not_found", l_user = Void)

			l_db.close
		end

	test_exists
			-- Test exists check
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.exists"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table
			l_repo.seed_data

			assert_true ("id_1_exists", l_repo.exists (1))
			assert_true ("id_2_exists", l_repo.exists (2))
			assert_false ("id_999_not_exists", l_repo.exists (999))

			l_db.close
		end

feature -- Test routines: Find Where

	test_find_where
			-- Test conditional query
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.find_where"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
			l_users: ARRAYED_LIST [TEST_USER_ENTITY]
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table
			l_repo.seed_data

			-- Find users over 25
			l_users := l_repo.find_where ("age > 25")
			assert_equal ("two_users_over_25", 2, l_users.count)

			-- Find specific status
			l_users := l_repo.find_where ("status = 'active'")
			assert_equal ("two_active", 2, l_users.count)

			l_db.close
		end

	test_find_where_ordered
			-- Test conditional query with ordering
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.find_where_ordered"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
			l_users: ARRAYED_LIST [TEST_USER_ENTITY]
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table
			l_repo.seed_data

			l_users := l_repo.find_where_ordered ("status = 'active'", "age DESC")
			assert_equal ("two_active", 2, l_users.count)
			-- Charlie (35) should be first, Alice (30) second
			assert_strings_equal ("oldest_first", "Charlie", l_users.first.name)

			l_db.close
		end

	test_find_first_where
			-- Test finding first matching record
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.find_first_where"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
			l_user: detachable TEST_USER_ENTITY
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table
			l_repo.seed_data

			l_user := l_repo.find_first_where ("status = 'inactive'")
			assert_true ("found_inactive", attached l_user)
			if attached l_user as u then
				assert_strings_equal ("bob_inactive", "Bob", u.name)
			end

			-- No match
			l_user := l_repo.find_first_where ("status = 'deleted'")
			assert_true ("no_deleted", l_user = Void)

			l_db.close
		end

feature -- Test routines: Counting

	test_count
			-- Test counting all records
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.count"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table

			assert_equal ("empty_count", 0, l_repo.count)

			l_repo.seed_data
			assert_equal ("seeded_count", 3, l_repo.count)

			l_db.close
		end

	test_count_where
			-- Test conditional counting
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.count_where"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table
			l_repo.seed_data

			assert_equal ("active_count", 2, l_repo.count_where ("status = 'active'"))
			assert_equal ("inactive_count", 1, l_repo.count_where ("status = 'inactive'"))
			assert_equal ("over_30", 1, l_repo.count_where ("age > 30"))

			l_db.close
		end

feature -- Test routines: Insert

	test_insert
			-- Test inserting new entity
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.insert"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
			l_user: TEST_USER_ENTITY
			l_new_id: INTEGER_64
			l_found: detachable TEST_USER_ENTITY
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table

			create l_user.make (0, "David", 28, "active")
			l_new_id := l_repo.insert (l_user)

			assert_true ("got_new_id", l_new_id > 0)
			assert_equal ("count_is_one", 1, l_repo.count)

			l_found := l_repo.find_by_id (l_new_id)
			assert_true ("can_find", attached l_found)
			if attached l_found as f then
				assert_strings_equal ("name_saved", "David", f.name)
				assert_equal ("age_saved", 28, f.age)
			end

			l_db.close
		end

	test_insert_multiple
			-- Test inserting multiple entities
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.insert"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
			l_user: TEST_USER_ENTITY
			l_id1, l_id2, l_id3: INTEGER_64
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table

			create l_user.make (0, "User1", 20, "active")
			l_id1 := l_repo.insert (l_user)

			create l_user.make (0, "User2", 21, "active")
			l_id2 := l_repo.insert (l_user)

			create l_user.make (0, "User3", 22, "active")
			l_id3 := l_repo.insert (l_user)

			assert_equal ("three_inserted", 3, l_repo.count)
			assert_true ("ids_sequential", l_id1 < l_id2 and l_id2 < l_id3)

			l_db.close
		end

feature -- Test routines: Update

	test_update
			-- Test updating existing entity
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.update"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
			l_user: TEST_USER_ENTITY
			l_found: detachable TEST_USER_ENTITY
			l_success: BOOLEAN
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table
			l_repo.seed_data

			-- Modify Alice (id=1)
			create l_user.make (1, "Alice Updated", 31, "inactive")
			l_success := l_repo.update (l_user)

			assert_true ("update_succeeded", l_success)

			l_found := l_repo.find_by_id (1)
			assert_true ("still_exists", attached l_found)
			if attached l_found as f then
				assert_strings_equal ("name_updated", "Alice Updated", f.name)
				assert_equal ("age_updated", 31, f.age)
				assert_strings_equal ("status_updated", "inactive", f.status)
			end

			l_db.close
		end

	test_update_nonexistent
			-- Test updating non-existent entity returns False
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.update"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
			l_user: TEST_USER_ENTITY
			l_success: BOOLEAN
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table
			l_repo.seed_data

			create l_user.make (999, "Ghost", 99, "active")
			l_success := l_repo.update (l_user)

			assert_false ("update_failed", l_success)

			l_db.close
		end

	test_update_where
			-- Test bulk update with conditions
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.update_where"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
			l_columns: HASH_TABLE [detachable ANY, STRING_8]
			l_affected: INTEGER
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table
			l_repo.seed_data

			create l_columns.make (1)
			l_columns.put ("archived", "status")

			l_affected := l_repo.update_where (l_columns, "status = 'inactive'")
			assert_equal ("one_updated", 1, l_affected)

			assert_equal ("none_inactive_now", 0, l_repo.count_where ("status = 'inactive'"))
			assert_equal ("one_archived", 1, l_repo.count_where ("status = 'archived'"))

			l_db.close
		end

feature -- Test routines: Delete

	test_delete
			-- Test deleting by ID
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.delete"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
			l_success: BOOLEAN
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table
			l_repo.seed_data

			assert_equal ("initial_count", 3, l_repo.count)

			l_success := l_repo.delete (1)
			assert_true ("delete_succeeded", l_success)
			assert_equal ("count_after_delete", 2, l_repo.count)
			assert_false ("alice_gone", l_repo.exists (1))

			l_db.close
		end

	test_delete_nonexistent
			-- Test deleting non-existent ID returns False
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.delete"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
			l_success: BOOLEAN
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table
			l_repo.seed_data

			l_success := l_repo.delete (999)
			assert_false ("delete_failed", l_success)
			assert_equal ("count_unchanged", 3, l_repo.count)

			l_db.close
		end

	test_delete_where
			-- Test bulk delete with conditions
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.delete_where"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
			l_deleted: INTEGER
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table
			l_repo.seed_data

			l_deleted := l_repo.delete_where ("status = 'inactive'")
			assert_equal ("one_deleted", 1, l_deleted)
			assert_equal ("two_remaining", 2, l_repo.count)

			l_db.close
		end

	test_delete_all
			-- Test deleting all records
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.delete_all"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
			l_deleted: INTEGER
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table
			l_repo.seed_data

			l_deleted := l_repo.delete_all
			assert_equal ("three_deleted", 3, l_deleted)
			assert_equal ("empty_now", 0, l_repo.count)

			l_db.close
		end

feature -- Test routines: Save (Insert or Update)

	test_save_new_entity
			-- Test save creates new entity
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.save"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
			l_user: TEST_USER_ENTITY
			l_id: INTEGER_64
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table

			create l_user.make (0, "New User", 25, "active")
			l_id := l_repo.save (l_user)

			assert_true ("got_id", l_id > 0)
			assert_equal ("count_is_one", 1, l_repo.count)

			l_db.close
		end

	test_save_existing_entity
			-- Test save updates existing entity
		note
			testing: "covers/{SIMPLE_SQL_REPOSITORY}.save"
		local
			l_db: SIMPLE_SQL_DATABASE
			l_repo: TEST_USER_REPOSITORY
			l_user: TEST_USER_ENTITY
			l_id: INTEGER_64
			l_found: detachable TEST_USER_ENTITY
		do
			create l_db.make_memory
			create l_repo.make (l_db)
			l_repo.create_table
			l_repo.seed_data

			-- Save with existing ID (update)
			create l_user.make (1, "Alice Modified", 32, "active")
			l_id := l_repo.save (l_user)

			assert_equal ("same_id", 1, l_id.to_integer_32)
			assert_equal ("count_unchanged", 3, l_repo.count)

			l_found := l_repo.find_by_id (1)
			if attached l_found as f then
				assert_strings_equal ("name_modified", "Alice Modified", f.name)
			end

			l_db.close
		end

end
