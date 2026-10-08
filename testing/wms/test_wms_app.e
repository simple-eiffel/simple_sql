note
	description: "Tests for WMS_APP - Warehouse Management System"
	testing: "covers"

class
	TEST_WMS_APP

inherit
	EQA_TEST_SET

feature -- Test: Warehouse

	test_create_warehouse
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-001", "Main Warehouse")

			assert ("not_new", not l_wh.is_new)
			assert ("has_id", l_wh.id > 0)
			assert_strings_equal ("code", "WH-001", l_wh.code)
			assert_strings_equal ("name", "Main Warehouse", l_wh.name)
			assert ("active", l_wh.is_active)

			l_app.close
		end

	test_find_warehouse
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-002", "Secondary")

			assert ("found", attached l_app.find_warehouse (l_wh.id) as found and then found.code.same_string ("WH-002"))
			assert ("not_found", not attached l_app.find_warehouse (9999))

			l_app.close
		end

feature -- Test: Product

	test_create_product
		local
			l_app: WMS_APP
			l_prod: WMS_PRODUCT
		do
			create l_app.make
			l_prod := l_app.create_product ("SKU-001", "Widget", "EA")

			assert ("not_new", not l_prod.is_new)
			assert_strings_equal ("sku", "SKU-001", l_prod.sku)
			assert_strings_equal ("name", "Widget", l_prod.name)
			assert_strings_equal ("unit", "EA", l_prod.unit_of_measure)

			l_app.close
		end

	test_find_product_by_sku
		local
			l_app: WMS_APP
			l_ignored: WMS_PRODUCT
		do
			create l_app.make
			l_ignored := l_app.create_product ("FINDME", "Find Me Product", "EA")

			assert ("found", attached l_app.find_product_by_sku ("FINDME"))
			assert ("not_found", not attached l_app.find_product_by_sku ("NOTEXIST"))

			l_app.close
		end

feature -- Test: Location

	test_create_location
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
			l_loc: WMS_LOCATION
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-LOC", "Location Test")
			l_loc := l_app.create_location (l_wh.id, "A", "01", "02", "B")

			assert ("not_new", not l_loc.is_new)
			assert_strings_equal ("code", "A-01-02-B", l_loc.code)
			assert_strings_equal ("aisle", "A", l_loc.aisle)
			assert ("active", l_loc.is_active)

			l_app.close
		end

	test_warehouse_locations
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
			l_ignored: WMS_LOCATION
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-MULTI", "Multi Location")
			l_ignored := l_app.create_location (l_wh.id, "A", "01", "01", "A")
			l_ignored := l_app.create_location (l_wh.id, "A", "01", "01", "B")
			l_ignored := l_app.create_location (l_wh.id, "A", "01", "02", "A")

			assert_integers_equal ("three_locations", 3, l_app.warehouse_locations (l_wh.id).count)

			l_app.close
		end

feature -- Test: Stock - Basic Operations

	test_receive_stock
			-- Test receiving stock at a new location (creates stock record).
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
			l_prod: WMS_PRODUCT
			l_loc: WMS_LOCATION
			l_success: BOOLEAN
			l_stock: detachable WMS_STOCK
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-RCV", "Receive Test")
			l_prod := l_app.create_product ("RCV-001", "Receivable", "EA")
			l_loc := l_app.create_location (l_wh.id, "A", "01", "01", "A")

			l_success := l_app.receive_stock (l_prod.id, l_loc.id, 100, "PO-001", 1)

			assert ("success", l_success)

			l_stock := l_app.find_stock (l_prod.id, l_loc.id)
			assert ("stock_created", attached l_stock)
			if attached l_stock as s then
				assert_integers_equal ("quantity", 100, s.quantity)
				assert_integers_equal ("reserved", 0, s.reserved_quantity)
				assert ("version_1", s.version = 1)
			end

			l_app.close
		end

	test_receive_stock_adds_to_existing
			-- Test receiving more stock at existing location (updates stock).
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
			l_prod: WMS_PRODUCT
			l_loc: WMS_LOCATION
			l_success: BOOLEAN
			l_stock: detachable WMS_STOCK
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-ADD", "Add Test")
			l_prod := l_app.create_product ("ADD-001", "Addable", "EA")
			l_loc := l_app.create_location (l_wh.id, "B", "01", "01", "A")

			l_success := l_app.receive_stock (l_prod.id, l_loc.id, 50, "PO-001", 1)
			assert ("first_receive", l_success)

			l_success := l_app.receive_stock (l_prod.id, l_loc.id, 30, "PO-002", 1)
			assert ("second_receive", l_success)

			l_stock := l_app.find_stock (l_prod.id, l_loc.id)
			if attached l_stock as s then
				assert_integers_equal ("total_quantity", 80, s.quantity)
				assert ("version_incremented", s.version = 2)
			end

			l_app.close
		end

	test_transfer_stock
			-- Test transferring stock between locations.
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
			l_prod: WMS_PRODUCT
			l_loc1, l_loc2: WMS_LOCATION
			l_success: BOOLEAN
			l_from_stock, l_to_stock: detachable WMS_STOCK
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-XFR", "Transfer Test")
			l_prod := l_app.create_product ("XFR-001", "Transferable", "EA")
			l_loc1 := l_app.create_location (l_wh.id, "A", "01", "01", "A")
			l_loc2 := l_app.create_location (l_wh.id, "B", "01", "01", "A")

			-- Receive at loc1
			l_success := l_app.receive_stock (l_prod.id, l_loc1.id, 100, "PO-001", 1)
			assert ("received", l_success)

			-- Transfer to loc2
			l_success := l_app.transfer_stock (l_prod.id, l_loc1.id, l_loc2.id, 40, "TRF-001", 1)
			assert ("transferred", l_success)

			l_from_stock := l_app.find_stock (l_prod.id, l_loc1.id)
			l_to_stock := l_app.find_stock (l_prod.id, l_loc2.id)

			if attached l_from_stock as fs then
				assert_integers_equal ("from_quantity", 60, fs.quantity)
			end
			if attached l_to_stock as ts then
				assert_integers_equal ("to_quantity", 40, ts.quantity)
			end

			l_app.close
		end

	test_transfer_insufficient_stock
			-- Test that transfer fails when insufficient stock.
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
			l_prod: WMS_PRODUCT
			l_loc1, l_loc2: WMS_LOCATION
			l_success: BOOLEAN
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-INS", "Insufficient Test")
			l_prod := l_app.create_product ("INS-001", "Limited", "EA")
			l_loc1 := l_app.create_location (l_wh.id, "A", "01", "01", "A")
			l_loc2 := l_app.create_location (l_wh.id, "B", "01", "01", "A")

			l_success := l_app.receive_stock (l_prod.id, l_loc1.id, 10, "PO-001", 1)

			-- Try to transfer more than available
			l_success := l_app.transfer_stock (l_prod.id, l_loc1.id, l_loc2.id, 50, "TRF-001", 1)
			assert ("transfer_failed", not l_success)

			-- Original stock unchanged
			if attached l_app.find_stock (l_prod.id, l_loc1.id) as s then
				assert_integers_equal ("unchanged", 10, s.quantity)
			end

			l_app.close
		end

feature -- Test: Stock Aggregation

	test_total_stock_for_product
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
			l_prod: WMS_PRODUCT
			l_loc1, l_loc2: WMS_LOCATION
			l_ignored: BOOLEAN
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-TOT", "Total Test")
			l_prod := l_app.create_product ("TOT-001", "Totaled", "EA")
			l_loc1 := l_app.create_location (l_wh.id, "A", "01", "01", "A")
			l_loc2 := l_app.create_location (l_wh.id, "B", "01", "01", "A")

			l_ignored := l_app.receive_stock (l_prod.id, l_loc1.id, 100, "PO-001", 1)
			l_ignored := l_app.receive_stock (l_prod.id, l_loc2.id, 50, "PO-002", 1)

			assert_integers_equal ("total", 150, l_app.total_stock_for_product (l_prod.id))

			l_app.close
		end

feature -- Test: Reservations

	test_reserve_stock
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
			l_prod: WMS_PRODUCT
			l_loc: WMS_LOCATION
			l_res: detachable WMS_RESERVATION
			l_ignored: BOOLEAN
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-RES", "Reserve Test")
			l_prod := l_app.create_product ("RES-001", "Reservable", "EA")
			l_loc := l_app.create_location (l_wh.id, "A", "01", "01", "A")

			l_ignored := l_app.receive_stock (l_prod.id, l_loc.id, 100, "PO-001", 1)

			l_res := l_app.reserve_stock (l_prod.id, l_loc.id, 30, "ORD-001", 1, 60)

			assert ("reserved", attached l_res)
			if attached l_res as r then
				assert_integers_equal ("res_qty", 30, r.quantity)
				assert_strings_equal ("order", "ORD-001", r.order_reference)
			end

			-- Check stock shows reserved quantity
			if attached l_app.find_stock (l_prod.id, l_loc.id) as s then
				assert_integers_equal ("stock_qty", 100, s.quantity)
				assert_integers_equal ("reserved_qty", 30, s.reserved_quantity)
				assert_integers_equal ("available", 70, s.available_quantity)
			end

			l_app.close
		end

	test_reserve_insufficient_available
			-- Can't reserve more than available (excluding already reserved).
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
			l_prod: WMS_PRODUCT
			l_loc: WMS_LOCATION
			l_res1, l_res2: detachable WMS_RESERVATION
			l_ignored: BOOLEAN
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-NORES", "No Reserve Test")
			l_prod := l_app.create_product ("NORES-001", "Limited Reserve", "EA")
			l_loc := l_app.create_location (l_wh.id, "A", "01", "01", "A")

			l_ignored := l_app.receive_stock (l_prod.id, l_loc.id, 50, "PO-001", 1)

			-- Reserve 40 of 50
			l_res1 := l_app.reserve_stock (l_prod.id, l_loc.id, 40, "ORD-001", 1, 60)
			assert ("first_ok", attached l_res1)

			-- Try to reserve 20 more (only 10 available)
			l_res2 := l_app.reserve_stock (l_prod.id, l_loc.id, 20, "ORD-002", 1, 60)
			assert ("second_failed", not attached l_res2)

			l_app.close
		end

	test_release_reservation
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
			l_prod: WMS_PRODUCT
			l_loc: WMS_LOCATION
			l_res: detachable WMS_RESERVATION
			l_released: BOOLEAN
			l_ignored: BOOLEAN
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-REL", "Release Test")
			l_prod := l_app.create_product ("REL-001", "Releasable", "EA")
			l_loc := l_app.create_location (l_wh.id, "A", "01", "01", "A")

			l_ignored := l_app.receive_stock (l_prod.id, l_loc.id, 100, "PO-001", 1)
			l_res := l_app.reserve_stock (l_prod.id, l_loc.id, 30, "ORD-001", 1, 60)

			if attached l_res as r then
				l_released := l_app.release_reservation (r.id)
				assert ("released", l_released)

				-- Stock should be fully available again
				if attached l_app.find_stock (l_prod.id, l_loc.id) as s then
					assert_integers_equal ("reserved_zero", 0, s.reserved_quantity)
					assert_integers_equal ("available_full", 100, s.available_quantity)
				end

				-- Reservation should be gone
				assert ("res_deleted", not attached l_app.find_reservation (r.id))
			end

			l_app.close
		end

feature -- Test: Movement History

	test_movements_recorded
			-- Verify movements are recorded for receive/transfer operations.
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
			l_prod: WMS_PRODUCT
			l_loc1, l_loc2: WMS_LOCATION
			l_movements: ARRAYED_LIST [WMS_MOVEMENT]
			l_ignored: BOOLEAN
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-MOV", "Movement Test")
			l_prod := l_app.create_product ("MOV-001", "Tracked", "EA")
			l_loc1 := l_app.create_location (l_wh.id, "A", "01", "01", "A")
			l_loc2 := l_app.create_location (l_wh.id, "B", "01", "01", "A")

			l_ignored := l_app.receive_stock (l_prod.id, l_loc1.id, 100, "PO-001", 1)
			l_ignored := l_app.transfer_stock (l_prod.id, l_loc1.id, l_loc2.id, 30, "TRF-001", 1)

			l_movements := l_app.movements_for_product (l_prod.id, 10)

			assert_integers_equal ("two_movements", 2, l_movements.count)
			-- Most recent first
			assert_strings_equal ("first_is_transfer", "TRANSFER", l_movements.first.movement_type)
			assert_strings_equal ("second_is_receive", "RECEIVE", l_movements.last.movement_type)

			l_app.close
		end

feature -- Test: Low Stock Alerts

	test_products_below_min_stock
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
			l_prod1, l_prod2: WMS_PRODUCT
			l_loc: WMS_LOCATION
			l_alerts: ARRAYED_LIST [TUPLE [product: WMS_PRODUCT; total: INTEGER; min: INTEGER]]
			l_ignored: BOOLEAN
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-LOW", "Low Stock Test")
			l_loc := l_app.create_location (l_wh.id, "A", "01", "01", "A")

			-- Product with min_stock = 50, actual = 20 (BELOW)
			l_prod1 := l_app.create_product ("LOW-001", "Low Stock Item", "EA")
			l_prod1.set_min_stock_level (50)
			l_app.database.execute_with_args ("UPDATE products SET min_stock_level = 50 WHERE id = ?;", <<l_prod1.id>>)
			l_ignored := l_app.receive_stock (l_prod1.id, l_loc.id, 20, "PO-001", 1)

			-- Product with min_stock = 10, actual = 100 (OK)
			l_prod2 := l_app.create_product ("OK-001", "OK Stock Item", "EA")
			l_app.database.execute_with_args ("UPDATE products SET min_stock_level = 10 WHERE id = ?;", <<l_prod2.id>>)
			l_ignored := l_app.receive_stock (l_prod2.id, l_loc.id, 100, "PO-002", 1)

			l_alerts := l_app.products_below_min_stock

			assert_integers_equal ("one_alert", 1, l_alerts.count)
			assert_strings_equal ("low_product", "LOW-001", l_alerts.first.product.sku)
			assert_integers_equal ("total", 20, l_alerts.first.total)
			assert_integers_equal ("min", 50, l_alerts.first.min)

			l_app.close
		end

feature {NONE} -- Helpers

	assert_strings_equal (a_tag: STRING; a_expected, a_actual: READABLE_STRING_8)
		do
			assert (a_tag, a_expected.same_string (a_actual))
		end

	assert_integers_equal (a_tag: STRING; a_expected, a_actual: INTEGER)
		do
			assert (a_tag, a_expected = a_actual)
		end

end
