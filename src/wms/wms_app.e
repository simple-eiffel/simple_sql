note
	description: "[
		WMS Application Facade - Warehouse Management System demonstrating concurrency friction.

		This mock application is designed to expose API gaps in SIMPLE_SQL around:
		- Optimistic locking (version-based conflict detection)
		- Atomic multi-table operations (stock + movement in one transaction)
		- Conditional updates (decrement only if sufficient)
		- Time-based expiry (reservation cleanup)
		- Upsert patterns (INSERT OR UPDATE stock)
		- Concurrent access handling

		FRICTION LOG (document each pain point as discovered):

		[F1] OPTIMISTIC LOCKING - receive_stock, transfer_stock
		     Current: Manual version check + retry loop
		     Desired: db.update_with_version (table, id, version, changes) -> {ok|conflict}

		[F2] ATOMIC STOCK+MOVEMENT - Every stock change needs audit trail
		     Current: begin_transaction + multiple executes + manual rollback
		     Desired: db.atomic (agent) with automatic retry on conflict

		[F3] CONDITIONAL DECREMENT - Can't decrement below zero
		     Current: SELECT to check, then UPDATE (race condition!)
		     Desired: db.decrement_if (table, column, amount, condition) -> success?

		[F4] UPSERT STOCK - Receive to new location should create or update
		     Current: Check exists, then INSERT or UPDATE
		     Desired: db.upsert (table, data, conflict_columns)

		[F5] EXPIRY CLEANUP - Release expired reservations
		     Current: Query expired, loop with individual releases
		     Desired: db.expire_and_callback (table, expiry_col, agent)

		[F6] RESERVATION CONFLICT - Two users reserve same stock simultaneously
		     Current: Hope for the best (race condition)
		     Desired: db.reserve_atomic (check + reserve in single statement)
	]"

class
	WMS_APP

create
	make,
	make_with_file

feature {NONE} -- Initialization

	make
			-- Initialize WMS with in-memory database.
		do
			create database.make_memory
			initialize_schema
		end

	make_with_file (a_path: READABLE_STRING_8)
			-- Initialize WMS with file-based database.
		require
			path_not_empty: not a_path.is_empty
		do
			create database.make (a_path)
			initialize_schema
		end

feature -- Access

	database: SIMPLE_SQL_DATABASE

feature -- Database Management

	close
		do
			database.close
		end

feature {NONE} -- Schema

	initialize_schema
		do
			create_warehouses_table
			create_products_table
			create_locations_table
			create_stock_table
			create_movements_table
			create_reservations_table
			create_indexes
		end

	create_warehouses_table
		do
			database.execute ("CREATE TABLE IF NOT EXISTS warehouses (id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT NOT NULL UNIQUE, name TEXT NOT NULL, address TEXT NOT NULL DEFAULT '', is_active INTEGER NOT NULL DEFAULT 1, created_at TEXT NOT NULL DEFAULT (datetime('now')));")
		end

	create_products_table
		do
			database.execute ("CREATE TABLE IF NOT EXISTS products (id INTEGER PRIMARY KEY AUTOINCREMENT, sku TEXT NOT NULL UNIQUE, name TEXT NOT NULL, description TEXT NOT NULL DEFAULT '', unit_of_measure TEXT NOT NULL DEFAULT 'EA', min_stock_level INTEGER NOT NULL DEFAULT 0, deleted_at TEXT);")
		end

	create_locations_table
		do
			database.execute ("CREATE TABLE IF NOT EXISTS locations (id INTEGER PRIMARY KEY AUTOINCREMENT, warehouse_id INTEGER NOT NULL REFERENCES warehouses(id), code TEXT NOT NULL, aisle TEXT NOT NULL DEFAULT '', rack TEXT NOT NULL DEFAULT '', shelf TEXT NOT NULL DEFAULT '', bin TEXT NOT NULL DEFAULT '', is_active INTEGER NOT NULL DEFAULT 1, UNIQUE(warehouse_id, code));")
		end

	create_stock_table
		do
			database.execute ("CREATE TABLE IF NOT EXISTS stock (id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER NOT NULL REFERENCES products(id), location_id INTEGER NOT NULL REFERENCES locations(id), quantity INTEGER NOT NULL DEFAULT 0, reserved_quantity INTEGER NOT NULL DEFAULT 0, version INTEGER NOT NULL DEFAULT 1, updated_at TEXT NOT NULL DEFAULT (datetime('now')), UNIQUE(product_id, location_id));")
		end

	create_movements_table
		do
			database.execute ("CREATE TABLE IF NOT EXISTS movements (id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER NOT NULL REFERENCES products(id), from_location_id INTEGER REFERENCES locations(id), to_location_id INTEGER REFERENCES locations(id), quantity INTEGER NOT NULL, movement_type TEXT NOT NULL, reference TEXT NOT NULL DEFAULT '', performed_by INTEGER NOT NULL, created_at TEXT NOT NULL DEFAULT (datetime('now')));")
		end

	create_reservations_table
		do
			database.execute ("CREATE TABLE IF NOT EXISTS reservations (id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER NOT NULL REFERENCES products(id), location_id INTEGER NOT NULL REFERENCES locations(id), quantity INTEGER NOT NULL, order_reference TEXT NOT NULL, reserved_by INTEGER NOT NULL, expires_at TEXT NOT NULL, created_at TEXT NOT NULL DEFAULT (datetime('now')));")
		end

	create_indexes
		do
			database.execute ("CREATE INDEX IF NOT EXISTS idx_stock_product ON stock(product_id);")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_stock_location ON stock(location_id);")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_movements_product ON movements(product_id);")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_movements_created ON movements(created_at);")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_reservations_expires ON reservations(expires_at);")
			database.execute ("CREATE INDEX IF NOT EXISTS idx_reservations_order ON reservations(order_reference);")
		end

feature -- Warehouse Operations

	create_warehouse (a_code, a_name: READABLE_STRING_8): WMS_WAREHOUSE
		require
			code_not_empty: not a_code.is_empty
			name_not_empty: not a_name.is_empty
		local
			l_id: INTEGER_64
		do
			database.execute_with_args ("INSERT INTO warehouses (code, name) VALUES (?, ?);", <<a_code, a_name>>)
			l_id := database.last_insert_rowid
			create Result.make_new (a_code, a_name)
			Result.set_id (l_id)
		ensure
			not_new: not Result.is_new
		end

	find_warehouse (a_id: INTEGER_64): detachable WMS_WAREHOUSE
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT * FROM warehouses WHERE id = ?;", <<a_id>>)
			if not l_result.rows.is_empty then
				Result := row_to_warehouse (l_result.rows.first)
			end
		end

	all_warehouses: ARRAYED_LIST [WMS_WAREHOUSE]
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (10)
			l_result := database.query ("SELECT * FROM warehouses WHERE is_active = 1 ORDER BY code;")
			across l_result.rows as row loop
				Result.extend (row_to_warehouse (row))
			end
		end

feature -- Product Operations

	create_product (a_sku, a_name, a_unit: READABLE_STRING_8): WMS_PRODUCT
		require
			sku_not_empty: not a_sku.is_empty
			name_not_empty: not a_name.is_empty
		local
			l_id: INTEGER_64
		do
			database.execute_with_args ("INSERT INTO products (sku, name, unit_of_measure) VALUES (?, ?, ?);", <<a_sku, a_name, a_unit>>)
			l_id := database.last_insert_rowid
			create Result.make_new (a_sku, a_name, a_unit)
			Result.set_id (l_id)
		end

	find_product (a_id: INTEGER_64): detachable WMS_PRODUCT
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT * FROM products WHERE id = ?;", <<a_id>>)
			if not l_result.rows.is_empty then
				Result := row_to_product (l_result.rows.first)
			end
		end

	find_product_by_sku (a_sku: READABLE_STRING_8): detachable WMS_PRODUCT
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT * FROM products WHERE sku = ? AND deleted_at IS NULL;", <<a_sku>>)
			if not l_result.rows.is_empty then
				Result := row_to_product (l_result.rows.first)
			end
		end

feature -- Location Operations

	create_location (a_warehouse_id: INTEGER_64; a_aisle, a_rack, a_shelf, a_bin: READABLE_STRING_8): WMS_LOCATION
		require
			valid_warehouse: a_warehouse_id > 0
		local
			l_id: INTEGER_64
			l_code: STRING_8
		do
			l_code := a_aisle + "-" + a_rack + "-" + a_shelf + "-" + a_bin
			database.execute_with_args ("INSERT INTO locations (warehouse_id, l_code, aisle, rack, shelf, bin) VALUES (?, ?, ?, ?, ?, ?);",
				<<a_warehouse_id, l_code, a_aisle, a_rack, a_shelf, a_bin>>)
			l_id := database.last_insert_rowid
			create Result.make_new (a_warehouse_id, a_aisle, a_rack, a_shelf, a_bin)
			Result.set_id (l_id)
		end

	find_location (a_id: INTEGER_64): detachable WMS_LOCATION
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT * FROM locations WHERE id = ?;", <<a_id>>)
			if not l_result.rows.is_empty then
				Result := row_to_location (l_result.rows.first)
			end
		end

	warehouse_locations (a_warehouse_id: INTEGER_64): ARRAYED_LIST [WMS_LOCATION]
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (50)
			l_result := database.query_with_args ("SELECT * FROM locations WHERE warehouse_id = ? AND is_active = 1 ORDER BY code;", <<a_warehouse_id>>)
			across l_result.rows as row loop
				Result.extend (row_to_location (row))
			end
		end

feature -- Stock Operations (FRICTION ZONE)

	receive_stock (a_product_id, a_location_id: INTEGER_64; a_quantity: INTEGER;
			a_reference: READABLE_STRING_8; a_user: INTEGER_64): BOOLEAN
			-- Receive stock at location. Returns True if successful.
			--
			-- PHASE 6 REFACTORED: Now uses db.atomic and db.upsert
			-- Compare to the original 45-line version with manual retry loops!
		require
			valid_product: a_product_id > 0
			valid_location: a_location_id > 0
			positive_quantity: a_quantity > 0
		local
			l_failed: BOOLEAN
		do
			if not l_failed then
				-- Use atomic to ensure stock update and movement are committed together
				database.atomic (agent receive_stock_operation (a_product_id, a_location_id, a_quantity, a_reference, a_user))
				Result := True
			end
		rescue
			l_failed := True
			retry
		end

	receive_stock_operation (a_product_id, a_location_id: INTEGER_64; a_quantity: INTEGER;
			a_reference: READABLE_STRING_8; a_user: INTEGER_64)
			-- Atomic operation for receive_stock.
		local
			l_stock: detachable WMS_STOCK
		do
			l_stock := find_stock (a_product_id, a_location_id)

			if attached l_stock as al_s then
				-- Update existing stock using increment_if (always succeeds when row exists)
				if database.increment_if ("l_stock", "quantity", a_quantity, "id = ?", <<al_s.id>>) then
					-- Also increment version
					database.execute_with_args ("UPDATE l_stock SET version = version + 1, updated_at = datetime('now') WHERE id = ?", <<al_s.id>>)
				end
			else
				-- Insert new stock record
				database.execute_with_args (
					"INSERT INTO l_stock (product_id, location_id, quantity, version) VALUES (?, ?, ?, 1);",
					<<a_product_id, a_location_id, a_quantity>>)
			end

			-- Record movement (always, part of atomic operation)
			database.execute_with_args (
				"INSERT INTO movements (product_id, to_location_id, quantity, movement_type, reference, performed_by) VALUES (?, ?, ?, 'RECEIVE', ?, ?);",
				<<a_product_id, a_location_id, a_quantity, a_reference, a_user>>)
		end

	transfer_stock (a_product_id, a_from_location, a_to_location: INTEGER_64;
			a_quantity: INTEGER; a_reference: READABLE_STRING_8; a_user: INTEGER_64): BOOLEAN
			-- Transfer stock between locations. Returns True if successful.
			--
			-- PHASE 6 REFACTORED: Now uses db.atomic and db.decrement_if
			-- Compare to the original 55-line version with nested loops!
		require
			valid_product: a_product_id > 0
			valid_from: a_from_location > 0
			valid_to: a_to_location > 0
			different_locations: a_from_location /= a_to_location
			positive_quantity: a_quantity > 0
		local
			l_from_stock: detachable WMS_STOCK
			l_failed: BOOLEAN
		do
			-- First check if source has sufficient stock
			l_from_stock := find_stock (a_product_id, a_from_location)

			if attached l_from_stock as fs and then fs.available_quantity >= a_quantity then
				if not l_failed then
					-- Use atomic to ensure all operations succeed or fail together
					database.atomic (agent transfer_stock_operation (a_product_id, a_from_location, a_to_location, a_quantity, a_reference, a_user, fs.id))
					Result := True
				end
			end
		rescue
			l_failed := True
			retry
		end

	transfer_stock_operation (a_product_id, a_from_location, a_to_location: INTEGER_64;
			a_quantity: INTEGER; a_reference: READABLE_STRING_8; a_user: INTEGER_64; a_from_stock_id: INTEGER_64)
			-- Atomic operation for transfer_stock.
		local
			l_to_stock: detachable WMS_STOCK
		do
			-- Decrement source using decrement_if (atomic check + update)
			if database.decrement_if ("stock", "quantity", a_quantity, "id = ? AND quantity >= ?", <<a_from_stock_id, a_quantity>>) then
				-- Update source version
				database.execute_with_args ("UPDATE stock SET version = version + 1, updated_at = datetime('now') WHERE id = ?", <<a_from_stock_id>>)

				-- Increment or create destination
				l_to_stock := find_stock (a_product_id, a_to_location)
				if attached l_to_stock as al_ts then
					if database.increment_if ("stock", "quantity", a_quantity, "id = ?", <<al_ts.id>>) then
						database.execute_with_args ("UPDATE stock SET version = version + 1, updated_at = datetime('now') WHERE id = ?", <<al_ts.id>>)
					end
				else
					database.execute_with_args (
						"INSERT INTO stock (product_id, location_id, quantity, version) VALUES (?, ?, ?, 1);",
						<<a_product_id, a_to_location, a_quantity>>)
				end

				-- Record movement
				database.execute_with_args (
					"INSERT INTO movements (product_id, from_location_id, to_location_id, quantity, movement_type, reference, performed_by) VALUES (?, ?, ?, ?, 'TRANSFER', ?, ?);",
					<<a_product_id, a_from_location, a_to_location, a_quantity, a_reference, a_user>>)
			else
				-- Decrement failed - raise exception to trigger rollback
				(create {DEVELOPER_EXCEPTION}).raise
			end
		end

	find_stock (a_product_id, a_location_id: INTEGER_64): detachable WMS_STOCK
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT * FROM stock WHERE product_id = ? AND location_id = ?;", <<a_product_id, a_location_id>>)
			if not l_result.rows.is_empty then
				Result := row_to_stock (l_result.rows.first)
			end
		end

	stock_at_location (a_location_id: INTEGER_64): ARRAYED_LIST [WMS_STOCK]
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (20)
			l_result := database.query_with_args ("SELECT * FROM stock WHERE location_id = ? AND quantity > 0;", <<a_location_id>>)
			across l_result.rows as row loop
				Result.extend (row_to_stock (row))
			end
		end

	total_stock_for_product (a_product_id: INTEGER_64): INTEGER
			-- Total quantity across all locations.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT COALESCE(SUM(quantity), 0) as total FROM stock WHERE product_id = ?;", <<a_product_id>>)
			if not l_result.rows.is_empty then
				Result := l_result.rows.first.integer_value ("total")
			end
		end

	available_stock_for_product (a_product_id: INTEGER_64): INTEGER
			-- Total available (not reserved) quantity across all locations.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT COALESCE(SUM(quantity - reserved_quantity), 0) as available FROM stock WHERE product_id = ?;", <<a_product_id>>)
			if not l_result.rows.is_empty then
				Result := l_result.rows.first.integer_value ("available")
			end
		end

feature -- Reservation Operations (FRICTION ZONE)

	reserve_stock (a_product_id, a_location_id: INTEGER_64; a_quantity: INTEGER;
			a_order_ref: READABLE_STRING_8; a_user: INTEGER_64;
			a_expires_minutes: INTEGER): detachable WMS_RESERVATION
			-- Reserve stock for an order. Returns reservation if successful.
			--
			-- FRICTION [F6]: Race condition between checking availability and reserving.
			-- Two users could both see "10 available", both try to reserve 10.
			--
			-- DESIRED: db.reserve_atomic (table, conditions, amount) that checks and reserves in one statement
		require
			valid_product: a_product_id > 0
			valid_location: a_location_id > 0
			positive_quantity: a_quantity > 0
			has_order: not a_order_ref.is_empty
			positive_expiry: a_expires_minutes > 0
		local
			l_stock: detachable WMS_STOCK
			l_version: INTEGER_64
			l_rows_affected: INTEGER
			l_expires: STRING_8
			l_id: INTEGER_64
			l_retries: INTEGER
		do
			-- [F6] RESERVATION RACE CONDITION
			-- Between checking available_quantity and updating, another user could reserve!
			-- DESIRED: Single atomic "UPDATE ... SET reserved = reserved + ? WHERE available >= ?"

			from
				l_retries := 0
			until
				attached Result or l_retries > 3
			loop
				l_stock := find_stock (a_product_id, a_location_id)

				if attached l_stock as s and then s.available_quantity >= a_quantity then
					l_version := s.version
					l_expires := "datetime('now', '+" + a_expires_minutes.out + " minutes')"

					database.begin_transaction

					-- Try to reserve with version check and availability check
					database.execute_with_args (
						"UPDATE l_stock SET reserved_quantity = reserved_quantity + ?, l_version = l_version + 1, updated_at = datetime('now') WHERE l_id = ? AND l_version = ? AND (quantity - reserved_quantity) >= ?;",
						<<a_quantity, s.id, l_version, a_quantity>>)
					l_rows_affected := database.changes_count

					if l_rows_affected = 0 then
						database.rollback
						l_retries := l_retries + 1
					else
						-- Create reservation record
						database.execute ("INSERT INTO reservations (product_id, location_id, quantity, order_reference, reserved_by, expires_at) VALUES (" +
							a_product_id.out + ", " + a_location_id.out + ", " + a_quantity.out + ", '" +
							a_order_ref + "', " + a_user.out + ", " + l_expires + ");")
						l_id := database.last_insert_rowid
						database.commit

						-- Retrieve the actual expires_at value from the inserted row
						Result := find_reservation (l_id)
					end
				else
					l_retries := 4 -- Exit - insufficient stock
				end
			end
		end

	release_reservation (a_reservation_id: INTEGER_64): BOOLEAN
			-- Release a reservation, making stock available again.
		local
			l_result: SIMPLE_SQL_RESULT
			l_product_id, l_location_id: INTEGER_64
			l_quantity: INTEGER
		do
			l_result := database.query_with_args ("SELECT l_product_id, l_location_id, l_quantity FROM reservations WHERE id = ?;", <<a_reservation_id>>)
			if not l_result.rows.is_empty then
				l_product_id := l_result.rows.first.integer_64_value ("l_product_id")
				l_location_id := l_result.rows.first.integer_64_value ("l_location_id")
				l_quantity := l_result.rows.first.integer_value ("l_quantity")

				database.begin_transaction
				database.execute_with_args ("UPDATE stock SET reserved_quantity = reserved_quantity - ?, version = version + 1 WHERE l_product_id = ? AND l_location_id = ?;",
					<<l_quantity, l_product_id, l_location_id>>)
				database.execute_with_args ("DELETE FROM reservations WHERE id = ?;", <<a_reservation_id>>)
				database.commit
				Result := True
			end
		end

	cleanup_expired_reservations: INTEGER
			-- Release all expired reservations. Returns count released.
			--
			-- FRICTION [F5]: Must query expired, loop, release each.
			-- DESIRED: db.cleanup_expired ("reservations", "expires_at", agent release_callback)
		local
			l_result: SIMPLE_SQL_RESULT
			l_ignored: BOOLEAN
		do
			l_result := database.query ("SELECT id FROM reservations WHERE expires_at < datetime('now');")
			across l_result.rows as row loop
				l_ignored := release_reservation (row.integer_64_value ("id"))
				if l_ignored then
					Result := Result + 1
				end
			end
		end

	find_reservation (a_id: INTEGER_64): detachable WMS_RESERVATION
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := database.query_with_args ("SELECT * FROM reservations WHERE id = ?;", <<a_id>>)
			if not l_result.rows.is_empty then
				Result := row_to_reservation (l_result.rows.first)
			end
		end

	reservations_for_order (a_order_ref: READABLE_STRING_8): ARRAYED_LIST [WMS_RESERVATION]
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (5)
			l_result := database.query_with_args ("SELECT * FROM reservations WHERE order_reference = ?;", <<a_order_ref>>)
			across l_result.rows as row loop
				Result.extend (row_to_reservation (row))
			end
		end

feature -- Movement Operations

	movements_for_product (a_product_id: INTEGER_64; a_limit: INTEGER): ARRAYED_LIST [WMS_MOVEMENT]
			-- Recent movements for a product.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (a_limit)
			l_result := database.query_with_args (
				"SELECT * FROM movements WHERE product_id = ? ORDER BY created_at DESC, id DESC LIMIT ?;",
				<<a_product_id, a_limit>>)
			across l_result.rows as row loop
				Result.extend (row_to_movement (row))
			end
		end

	movements_at_location (a_location_id: INTEGER_64; a_limit: INTEGER): ARRAYED_LIST [WMS_MOVEMENT]
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (a_limit)
			l_result := database.query_with_args (
				"SELECT * FROM movements WHERE from_location_id = ? OR to_location_id = ? ORDER BY created_at DESC, id DESC LIMIT ?;",
				<<a_location_id, a_location_id, a_limit>>)
			across l_result.rows as row loop
				Result.extend (row_to_movement (row))
			end
		end

feature -- Low Stock Alerts

	products_below_min_stock: ARRAYED_LIST [TUPLE [product: WMS_PRODUCT; total: INTEGER; min: INTEGER]]
			-- Products where total stock is below minimum level.
			--
			-- FRICTION: Aggregation + join, but this is actually clean with current API.
		local
			l_result: SIMPLE_SQL_RESULT
			l_product: WMS_PRODUCT
		do
			create Result.make (10)
			l_result := database.query ("[
				SELECT p.*, COALESCE(SUM(s.quantity), 0) as total_qty
				FROM products p
				LEFT JOIN stock s ON s.product_id = p.id
				WHERE p.deleted_at IS NULL AND p.min_stock_level > 0
				GROUP BY p.id
				HAVING total_qty < p.min_stock_level
				ORDER BY (p.min_stock_level - total_qty) DESC
			]")
			across l_result.rows as row loop
				l_product := row_to_product (row)
				Result.extend ([l_product, row.integer_value ("total_qty"), l_product.min_stock_level])
			end
		end

feature {NONE} -- Row Mapping

	row_to_warehouse (a_row: SIMPLE_SQL_ROW): WMS_WAREHOUSE
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.string_value ("code").to_string_8,
				a_row.string_value ("name").to_string_8,
				a_row.string_value ("address").to_string_8,
				a_row.integer_value ("is_active") = 1,
				a_row.string_value ("created_at").to_string_8)
		end

	row_to_product (a_row: SIMPLE_SQL_ROW): WMS_PRODUCT
		local
			l_deleted: detachable STRING_8
		do
			if not a_row.is_null ("deleted_at") then
				l_deleted := a_row.string_value ("deleted_at").to_string_8
			end
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.string_value ("sku").to_string_8,
				a_row.string_value ("name").to_string_8,
				a_row.string_value ("description").to_string_8,
				a_row.string_value ("unit_of_measure").to_string_8,
				a_row.integer_value ("min_stock_level"),
				l_deleted)
		end

	row_to_location (a_row: SIMPLE_SQL_ROW): WMS_LOCATION
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.integer_64_value ("warehouse_id"),
				a_row.string_value ("code").to_string_8,
				a_row.string_value ("aisle").to_string_8,
				a_row.string_value ("rack").to_string_8,
				a_row.string_value ("shelf").to_string_8,
				a_row.string_value ("bin").to_string_8,
				a_row.integer_value ("is_active") = 1)
		end

	row_to_stock (a_row: SIMPLE_SQL_ROW): WMS_STOCK
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.integer_64_value ("product_id"),
				a_row.integer_64_value ("location_id"),
				a_row.integer_value ("quantity"),
				a_row.integer_value ("reserved_quantity"),
				a_row.integer_64_value ("version"),
				a_row.string_value ("updated_at").to_string_8)
		end

	row_to_movement (a_row: SIMPLE_SQL_ROW): WMS_MOVEMENT
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.integer_64_value ("product_id"),
				a_row.integer_64_value ("from_location_id"),
				a_row.integer_64_value ("to_location_id"),
				a_row.integer_value ("quantity"),
				a_row.string_value ("movement_type").to_string_8,
				a_row.string_value ("reference").to_string_8,
				a_row.integer_64_value ("performed_by"),
				a_row.string_value ("created_at").to_string_8)
		end

	row_to_reservation (a_row: SIMPLE_SQL_ROW): WMS_RESERVATION
		do
			create Result.make (
				a_row.integer_64_value ("id"),
				a_row.integer_64_value ("product_id"),
				a_row.integer_64_value ("location_id"),
				a_row.integer_value ("quantity"),
				a_row.string_value ("order_reference").to_string_8,
				a_row.integer_64_value ("reserved_by"),
				a_row.string_value ("expires_at").to_string_8,
				a_row.string_value ("created_at").to_string_8)
		end

end
