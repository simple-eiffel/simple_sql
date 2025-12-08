note
	description: "Tests for Phase 6 Atomic Operations: atomic, update_versioned, upsert, decrement_if, increment_if"
	testing: "covers"
	testing: "execution/serial"

class
	TEST_PHASE6_ATOMIC

inherit
	TEST_SET_BASE

feature -- Test: atomic

	test_atomic_commits_on_success
			-- Verify atomic commits when operation succeeds
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			create l_db.make_memory
			setup_accounts_tables (l_db)
			l_db.execute ("INSERT INTO accounts (name, balance) VALUES ('Alice', 100)")
			l_db.execute ("INSERT INTO accounts (name, balance) VALUES ('Bob', 50)")

			l_db.atomic (agent transfer_funds (l_db, 1, 2, 25))

			assert_equal ("alice_balance", 75, account_balance (l_db, 1))
			assert_equal ("bob_balance", 75, account_balance (l_db, 2))
			assert_equal ("movement_recorded", 1, movement_count (l_db))

			l_db.close
		end

	test_atomic_rollback_on_failure
			-- Verify atomic rolls back when operation fails
		local
			l_db: SIMPLE_SQL_DATABASE
			l_failed: BOOLEAN
		do
			create l_db.make_memory
			setup_accounts_tables (l_db)

			if not l_failed then
				l_db.execute ("INSERT INTO accounts (name, balance) VALUES ('Alice', 100)")
				l_db.execute ("INSERT INTO accounts (name, balance) VALUES ('Bob', 50)")

				l_db.atomic (agent failing_transfer (l_db))
			end

			-- Balances should be unchanged after rollback
			assert_equal ("alice_unchanged", 100, account_balance (l_db, 1))
			assert_equal ("bob_unchanged", 50, account_balance (l_db, 2))
			assert_equal ("no_movement", 0, movement_count (l_db))

			l_db.close
		rescue
			l_failed := True
			retry
		end

feature -- Test: update_versioned

	test_update_versioned_success
			-- Verify versioned update succeeds with correct version
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: TUPLE [success: BOOLEAN; new_version: INTEGER_64]
		do
			create l_db.make_memory
			setup_stock_table (l_db)
			l_db.execute ("INSERT INTO stock (product_id, location_id, quantity, version) VALUES (1, 1, 100, 1)")

			l_result := l_db.update_versioned ("stock", 1, 1, "quantity = quantity + ?", <<50>>)

			assert_true ("update_succeeded", l_result.success)
			assert_equal ("new_version_is_2", {INTEGER_64} 2, l_result.new_version)
			assert_equal ("quantity_updated", 150, stock_quantity (l_db, 1))
			assert_equal ("version_incremented", {INTEGER_64} 2, stock_version (l_db, 1))

			l_db.close
		end

	test_update_versioned_fails_on_stale_version
			-- Verify versioned update fails when version is stale
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: TUPLE [success: BOOLEAN; new_version: INTEGER_64]
		do
			create l_db.make_memory
			setup_stock_table (l_db)
			l_db.execute ("INSERT INTO stock (product_id, location_id, quantity, version) VALUES (1, 1, 100, 5)")

			-- Try update with old version (3 instead of 5)
			l_result := l_db.update_versioned ("stock", 1, 3, "quantity = quantity + ?", <<50>>)

			assert_false ("update_failed", l_result.success)
			assert_equal ("new_version_is_zero", {INTEGER_64} 0, l_result.new_version)
			assert_equal ("quantity_unchanged", 100, stock_quantity (l_db, 1))
			assert_equal ("version_unchanged", {INTEGER_64} 5, stock_version (l_db, 1))

			l_db.close
		end

	test_update_versioned_multiple_columns
			-- Verify versioned update can update multiple columns
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: TUPLE [success: BOOLEAN; new_version: INTEGER_64]
		do
			create l_db.make_memory
			setup_stock_table (l_db)
			l_db.execute ("INSERT INTO stock (product_id, location_id, quantity, version) VALUES (1, 1, 100, 1)")

			l_result := l_db.update_versioned ("stock", 1, 1, "quantity = ?, location_id = ?", <<200, 2>>)

			assert_true ("update_succeeded", l_result.success)
			assert_equal ("quantity_set", 200, stock_quantity (l_db, 1))
			assert_equal ("location_changed", {INTEGER_64} 2, stock_location (l_db, 1))

			l_db.close
		end

feature -- Test: upsert

	test_upsert_inserts_new_row
			-- Verify upsert inserts when no conflict
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			create l_db.make_memory
			setup_stock_table (l_db)

			l_db.upsert ("stock",
				<<"product_id", "location_id", "quantity">>,
				<<1, 1, 100>>,
				<<"product_id", "location_id">>)

			assert_equal ("row_inserted", 1, stock_count (l_db))
			assert_equal ("quantity_set", 100, stock_quantity (l_db, 1))

			l_db.close
		end

	test_upsert_updates_existing_row
			-- Verify upsert updates on conflict
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			create l_db.make_memory
			setup_stock_table (l_db)

			-- Insert initial row
			l_db.execute ("INSERT INTO stock (product_id, location_id, quantity) VALUES (1, 1, 100)")

			-- Upsert with same key should update
			l_db.upsert ("stock",
				<<"product_id", "location_id", "quantity">>,
				<<1, 1, 250>>,
				<<"product_id", "location_id">>)

			assert_equal ("still_one_row", 1, stock_count (l_db))
			assert_equal ("quantity_updated", 250, first_stock_quantity (l_db))

			l_db.close
		end

	test_upsert_multiple_rows
			-- Verify multiple upserts work correctly
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			create l_db.make_memory
			setup_stock_table (l_db)

			-- Insert via upsert
			l_db.upsert ("stock", <<"product_id", "location_id", "quantity">>, <<1, 1, 100>>, <<"product_id", "location_id">>)
			l_db.upsert ("stock", <<"product_id", "location_id", "quantity">>, <<1, 2, 50>>, <<"product_id", "location_id">>)
			l_db.upsert ("stock", <<"product_id", "location_id", "quantity">>, <<2, 1, 75>>, <<"product_id", "location_id">>)

			-- Update one via upsert
			l_db.upsert ("stock", <<"product_id", "location_id", "quantity">>, <<1, 1, 200>>, <<"product_id", "location_id">>)

			assert_equal ("three_rows", 3, stock_count (l_db))
			assert_equal ("first_updated", 200, stock_quantity_by_product_location (l_db, 1, 1))
			assert_equal ("second_unchanged", 50, stock_quantity_by_product_location (l_db, 1, 2))
			assert_equal ("third_unchanged", 75, stock_quantity_by_product_location (l_db, 2, 1))

			l_db.close
		end

feature -- Test: decrement_if

	test_decrement_if_succeeds_when_sufficient
			-- Verify decrement succeeds when value is sufficient
		local
			l_db: SIMPLE_SQL_DATABASE
			l_success: BOOLEAN
		do
			create l_db.make_memory
			setup_stock_table (l_db)
			l_db.execute ("INSERT INTO stock (product_id, location_id, quantity) VALUES (1, 1, 100)")

			l_success := l_db.decrement_if ("stock", "quantity", 30, "id = ? AND quantity >= ?", <<1, 30>>)

			assert_true ("decrement_succeeded", l_success)
			assert_equal ("quantity_decremented", 70, stock_quantity (l_db, 1))

			l_db.close
		end

	test_decrement_if_fails_when_insufficient
			-- Verify decrement fails when value is insufficient
		local
			l_db: SIMPLE_SQL_DATABASE
			l_success: BOOLEAN
		do
			create l_db.make_memory
			setup_stock_table (l_db)
			l_db.execute ("INSERT INTO stock (product_id, location_id, quantity) VALUES (1, 1, 20)")

			l_success := l_db.decrement_if ("stock", "quantity", 30, "id = ? AND quantity >= ?", <<1, 30>>)

			assert_false ("decrement_failed", l_success)
			assert_equal ("quantity_unchanged", 20, stock_quantity (l_db, 1))

			l_db.close
		end

	test_decrement_if_fails_when_row_not_found
			-- Verify decrement fails when row doesn't exist
		local
			l_db: SIMPLE_SQL_DATABASE
			l_success: BOOLEAN
		do
			create l_db.make_memory
			setup_stock_table (l_db)

			l_success := l_db.decrement_if ("stock", "quantity", 10, "id = ?", <<999>>)

			assert_false ("decrement_failed", l_success)

			l_db.close
		end

	test_decrement_if_atomic
			-- Verify decrement is atomic (no race condition)
		local
			l_db: SIMPLE_SQL_DATABASE
			l_success1, l_success2: BOOLEAN
		do
			create l_db.make_memory
			setup_stock_table (l_db)
			l_db.execute ("INSERT INTO stock (product_id, location_id, quantity) VALUES (1, 1, 50)")

			-- Both try to decrement by 30 (only one should succeed)
			l_success1 := l_db.decrement_if ("stock", "quantity", 30, "id = ? AND quantity >= ?", <<1, 30>>)
			l_success2 := l_db.decrement_if ("stock", "quantity", 30, "id = ? AND quantity >= ?", <<1, 30>>)

			assert_true ("first_succeeded", l_success1)
			assert_false ("second_failed", l_success2)
			assert_equal ("quantity_is_20", 20, stock_quantity (l_db, 1))

			l_db.close
		end

feature -- Test: increment_if

	test_increment_if_succeeds
			-- Verify increment succeeds when condition met
		local
			l_db: SIMPLE_SQL_DATABASE
			l_success: BOOLEAN
		do
			create l_db.make_memory
			setup_stock_table (l_db)
			l_db.execute ("INSERT INTO stock (product_id, location_id, quantity) VALUES (1, 1, 100)")

			l_success := l_db.increment_if ("stock", "quantity", 50, "id = ?", <<1>>)

			assert_true ("increment_succeeded", l_success)
			assert_equal ("quantity_incremented", 150, stock_quantity (l_db, 1))

			l_db.close
		end

	test_increment_if_fails_when_row_not_found
			-- Verify increment fails when row doesn't exist
		local
			l_db: SIMPLE_SQL_DATABASE
			l_success: BOOLEAN
		do
			create l_db.make_memory
			setup_stock_table (l_db)

			l_success := l_db.increment_if ("stock", "quantity", 10, "id = ?", <<999>>)

			assert_false ("increment_failed", l_success)

			l_db.close
		end

	test_increment_if_with_complex_condition
			-- Verify increment with complex WHERE clause
		local
			l_db: SIMPLE_SQL_DATABASE
			l_success: BOOLEAN
		do
			create l_db.make_memory
			setup_stock_table (l_db)
			l_db.execute ("INSERT INTO stock (product_id, location_id, quantity) VALUES (1, 1, 100)")
			l_db.execute ("INSERT INTO stock (product_id, location_id, quantity) VALUES (1, 2, 50)")

			-- Only increment stock at location 1
			l_success := l_db.increment_if ("stock", "quantity", 25, "product_id = ? AND location_id = ?", <<1, 1>>)

			assert_true ("increment_succeeded", l_success)
			assert_equal ("location_1_incremented", 125, stock_quantity_by_product_location (l_db, 1, 1))
			assert_equal ("location_2_unchanged", 50, stock_quantity_by_product_location (l_db, 1, 2))

			l_db.close
		end

feature {NONE} -- Setup helpers

	setup_stock_table (a_db: SIMPLE_SQL_DATABASE)
			-- Create stock table
		do
			a_db.execute ("[
				CREATE TABLE stock (
					id INTEGER PRIMARY KEY,
					product_id INTEGER NOT NULL,
					location_id INTEGER NOT NULL,
					quantity INTEGER NOT NULL DEFAULT 0,
					version INTEGER NOT NULL DEFAULT 1,
					UNIQUE(product_id, location_id)
				)
			]")
		end

	setup_accounts_tables (a_db: SIMPLE_SQL_DATABASE)
			-- Create accounts and movements tables
		do
			a_db.execute ("[
				CREATE TABLE accounts (
					id INTEGER PRIMARY KEY,
					name TEXT NOT NULL,
					balance INTEGER NOT NULL DEFAULT 0
				)
			]")
			a_db.execute ("[
				CREATE TABLE movements (
					id INTEGER PRIMARY KEY,
					from_account_id INTEGER,
					to_account_id INTEGER,
					amount INTEGER NOT NULL,
					created_at TEXT DEFAULT (datetime('now'))
				)
			]")
		end

feature {NONE} -- Agent helpers

	transfer_funds (a_db: SIMPLE_SQL_DATABASE; a_from, a_to: INTEGER_64; a_amount: INTEGER)
			-- Transfer funds between accounts (for atomic test)
		do
			a_db.execute_with_args ("UPDATE accounts SET balance = balance - ? WHERE id = ?", <<a_amount, a_from>>)
			a_db.execute_with_args ("UPDATE accounts SET balance = balance + ? WHERE id = ?", <<a_amount, a_to>>)
			a_db.execute_with_args ("INSERT INTO movements (from_account_id, to_account_id, amount) VALUES (?, ?, ?)",
				<<a_from, a_to, a_amount>>)
		end

	failing_transfer (a_db: SIMPLE_SQL_DATABASE)
			-- Transfer that fails mid-way (for rollback test)
		do
			a_db.execute_with_args ("UPDATE accounts SET balance = balance - ? WHERE id = ?", <<25, 1>>)
			-- Cause failure before completing
			(create {DEVELOPER_EXCEPTION}).raise
		end

feature {NONE} -- Query helpers

	account_balance (a_db: SIMPLE_SQL_DATABASE; a_id: INTEGER_64): INTEGER
			-- Get account balance
		do
			if attached a_db.query_with_args ("SELECT balance FROM accounts WHERE id = ?", <<a_id>>).first as row then
				Result := row.integer_value ("balance")
			end
		end

	movement_count (a_db: SIMPLE_SQL_DATABASE): INTEGER
			-- Count movements
		do
			if attached a_db.query ("SELECT COUNT(*) as cnt FROM movements").first as row then
				Result := row.integer_value ("cnt")
			end
		end

	stock_quantity (a_db: SIMPLE_SQL_DATABASE; a_id: INTEGER_64): INTEGER
			-- Get stock quantity by id
		do
			if attached a_db.query_with_args ("SELECT quantity FROM stock WHERE id = ?", <<a_id>>).first as row then
				Result := row.integer_value ("quantity")
			end
		end

	stock_version (a_db: SIMPLE_SQL_DATABASE; a_id: INTEGER_64): INTEGER_64
			-- Get stock version by id
		do
			if attached a_db.query_with_args ("SELECT version FROM stock WHERE id = ?", <<a_id>>).first as row then
				Result := row.integer_64_value ("version")
			end
		end

	stock_location (a_db: SIMPLE_SQL_DATABASE; a_id: INTEGER_64): INTEGER_64
			-- Get stock location_id by id
		do
			if attached a_db.query_with_args ("SELECT location_id FROM stock WHERE id = ?", <<a_id>>).first as row then
				Result := row.integer_64_value ("location_id")
			end
		end

	stock_count (a_db: SIMPLE_SQL_DATABASE): INTEGER
			-- Count stock rows
		do
			if attached a_db.query ("SELECT COUNT(*) as cnt FROM stock").first as row then
				Result := row.integer_value ("cnt")
			end
		end

	first_stock_quantity (a_db: SIMPLE_SQL_DATABASE): INTEGER
			-- Get quantity of first stock row
		do
			if attached a_db.query ("SELECT quantity FROM stock ORDER BY id LIMIT 1").first as row then
				Result := row.integer_value ("quantity")
			end
		end

	stock_quantity_by_product_location (a_db: SIMPLE_SQL_DATABASE; a_product_id, a_location_id: INTEGER_64): INTEGER
			-- Get stock quantity by product and location
		do
			if attached a_db.query_with_args (
				"SELECT quantity FROM stock WHERE product_id = ? AND location_id = ?",
				<<a_product_id, a_location_id>>).first as row
			then
				Result := row.integer_value ("quantity")
			end
		end

end
