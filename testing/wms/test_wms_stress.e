note
	description: "[
		Stress tests for WMS_APP - exposing concurrency and edge case friction.

		These tests are designed to highlight API gaps in SIMPLE_SQL, particularly:
		- Optimistic locking retry patterns
		- Race conditions in reservation
		- Bulk operation efficiency
		- Edge cases around zero/negative quantities
	]"
	testing: "covers"

class
	TEST_WMS_STRESS

inherit
	EQA_TEST_SET

feature -- Test: Optimistic Locking Stress

	test_many_sequential_receives
			-- Many receives to same location should all succeed sequentially.
			-- This tests the optimistic locking retry mechanism.
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
			l_prod: WMS_PRODUCT
			l_loc: WMS_LOCATION
			l_success: BOOLEAN
			i: INTEGER
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-STRESS-1", "Stress 1")
			l_prod := l_app.create_product ("STRESS-001", "High Volume", "EA")
			l_loc := l_app.create_location (l_wh.id, "A", "01", "01", "A")

			-- 50 sequential receives of 10 each
			from i := 1 until i > 50 loop
				l_success := l_app.receive_stock (l_prod.id, l_loc.id, 10, "PO-" + i.out, 1)
				assert ("receive_" + i.out, l_success)
				i := i + 1
			end

			assert_integers_equal ("total", 500, l_app.total_stock_for_product (l_prod.id))

			-- Version should have been incremented 50 times (first creates, 49 updates)
			if attached l_app.find_stock (l_prod.id, l_loc.id) as s then
				assert ("version_high", s.version >= 49)
			end

			l_app.close
		end

	test_transfer_chain
			-- Transfer stock through a chain of locations.
			-- Tests multiple transfers in sequence.
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
			l_prod: WMS_PRODUCT
			l_locations: ARRAYED_LIST [WMS_LOCATION]
			l_success: BOOLEAN
			i: INTEGER
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-CHAIN", "Chain Test")
			l_prod := l_app.create_product ("CHAIN-001", "Chain Item", "EA")

			-- Create 10 locations
			create l_locations.make (10)
			from i := 1 until i > 10 loop
				l_locations.extend (l_app.create_location (l_wh.id, "A", i.out, "01", "A"))
				i := i + 1
			end

			-- Receive 100 at first location
			l_success := l_app.receive_stock (l_prod.id, l_locations.first.id, 100, "PO-INIT", 1)
			assert ("initial_receive", l_success)

			-- Transfer through chain: 1->2->3->...->10
			from i := 1 until i >= 10 loop
				l_success := l_app.transfer_stock (l_prod.id,
					l_locations.i_th (i).id, l_locations.i_th (i + 1).id,
					100, "XFR-" + i.out, 1)
				assert ("transfer_" + i.out, l_success)
				i := i + 1
			end

			-- All stock should be at last location
			if attached l_app.find_stock (l_prod.id, l_locations.first.id) as first_stock then
				assert_integers_equal ("first_empty", 0, first_stock.quantity)
			end
			if attached l_app.find_stock (l_prod.id, l_locations.last.id) as last_stock then
				assert_integers_equal ("last_full", 100, last_stock.quantity)
			end

			-- Total unchanged
			assert_integers_equal ("total_unchanged", 100, l_app.total_stock_for_product (l_prod.id))

			l_app.close
		end

feature -- Test: Reservation Edge Cases

	test_reserve_exact_available
			-- Reserve exactly what's available.
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
			l_prod: WMS_PRODUCT
			l_loc: WMS_LOCATION
			l_res: detachable WMS_RESERVATION
			l_ignored: BOOLEAN
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-EXACT", "Exact Test")
			l_prod := l_app.create_product ("EXACT-001", "Exact Qty", "EA")
			l_loc := l_app.create_location (l_wh.id, "A", "01", "01", "A")

			l_ignored := l_app.receive_stock (l_prod.id, l_loc.id, 100, "PO-001", 1)

			-- Reserve exactly 100
			l_res := l_app.reserve_stock (l_prod.id, l_loc.id, 100, "ORD-EXACT", 1, 60)
			assert ("exact_reserved", attached l_res)

			-- Available should be 0
			if attached l_app.find_stock (l_prod.id, l_loc.id) as s then
				assert_integers_equal ("zero_available", 0, s.available_quantity)
			end

			-- Cannot reserve any more
			l_res := l_app.reserve_stock (l_prod.id, l_loc.id, 1, "ORD-MORE", 1, 60)
			assert ("no_more", not attached l_res)

			l_app.close
		end

	test_multiple_reservations_same_stock
			-- Multiple reservations against same stock record.
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
			l_prod: WMS_PRODUCT
			l_loc: WMS_LOCATION
			l_res: detachable WMS_RESERVATION
			l_reservations: ARRAYED_LIST [WMS_RESERVATION]
			l_ignored: BOOLEAN
			i: INTEGER
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-MULTI-RES", "Multi Reserve")
			l_prod := l_app.create_product ("MULTI-001", "Multi Reserved", "EA")
			l_loc := l_app.create_location (l_wh.id, "A", "01", "01", "A")

			l_ignored := l_app.receive_stock (l_prod.id, l_loc.id, 100, "PO-001", 1)

			-- Create 10 reservations of 10 each
			create l_reservations.make (10)
			from i := 1 until i > 10 loop
				l_res := l_app.reserve_stock (l_prod.id, l_loc.id, 10, "ORD-" + i.out, 1, 60)
				assert ("res_" + i.out, attached l_res)
				if attached l_res as r then
					l_reservations.extend (r)
				end
				i := i + 1
			end

			-- All 100 should be reserved
			if attached l_app.find_stock (l_prod.id, l_loc.id) as s then
				assert_integers_equal ("all_reserved", 100, s.reserved_quantity)
				assert_integers_equal ("none_available", 0, s.available_quantity)
			end

			-- Release half
			from i := 1 until i > 5 loop
				l_ignored := l_app.release_reservation (l_reservations.i_th (i).id)
				i := i + 1
			end

			-- 50 should now be available
			if attached l_app.find_stock (l_prod.id, l_loc.id) as s then
				assert_integers_equal ("half_reserved", 50, s.reserved_quantity)
				assert_integers_equal ("half_available", 50, s.available_quantity)
			end

			l_app.close
		end

feature -- Test: Movement Audit Trail

	test_movement_audit_completeness
			-- Every stock change must have corresponding movement.
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
			l_prod: WMS_PRODUCT
			l_loc1, l_loc2: WMS_LOCATION
			l_movements: ARRAYED_LIST [WMS_MOVEMENT]
			l_total_in, l_total_out: INTEGER
			l_ignored: BOOLEAN
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-AUDIT", "Audit Test")
			l_prod := l_app.create_product ("AUDIT-001", "Audited", "EA")
			l_loc1 := l_app.create_location (l_wh.id, "A", "01", "01", "A")
			l_loc2 := l_app.create_location (l_wh.id, "B", "01", "01", "A")

			-- Various operations
			l_ignored := l_app.receive_stock (l_prod.id, l_loc1.id, 200, "PO-001", 1)
			l_ignored := l_app.transfer_stock (l_prod.id, l_loc1.id, l_loc2.id, 50, "XFR-001", 1)
			l_ignored := l_app.receive_stock (l_prod.id, l_loc2.id, 30, "PO-002", 1)
			l_ignored := l_app.transfer_stock (l_prod.id, l_loc2.id, l_loc1.id, 20, "XFR-002", 1)

			-- Calculate totals from movements
			l_movements := l_app.movements_for_product (l_prod.id, 100)
			across l_movements as m loop
				if m.is_receive then
					l_total_in := l_total_in + m.quantity
				elseif m.is_transfer then
					-- Transfers are internal, don't affect total
				end
			end

			-- Total from movements should equal total in stock
			assert_integers_equal ("audit_matches", l_total_in, l_app.total_stock_for_product (l_prod.id))

			l_app.close
		end

feature -- Test: Edge Cases

	test_transfer_all_stock
			-- Transfer entire quantity from location.
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
			l_prod: WMS_PRODUCT
			l_loc1, l_loc2: WMS_LOCATION
			l_success: BOOLEAN
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-ALL", "All Test")
			l_prod := l_app.create_product ("ALL-001", "All Item", "EA")
			l_loc1 := l_app.create_location (l_wh.id, "A", "01", "01", "A")
			l_loc2 := l_app.create_location (l_wh.id, "B", "01", "01", "A")

			l_success := l_app.receive_stock (l_prod.id, l_loc1.id, 50, "PO-001", 1)
			l_success := l_app.transfer_stock (l_prod.id, l_loc1.id, l_loc2.id, 50, "XFR-ALL", 1)
			assert ("transfer_all", l_success)

			-- Source should show 0
			if attached l_app.find_stock (l_prod.id, l_loc1.id) as s then
				assert_integers_equal ("source_zero", 0, s.quantity)
			end

			l_app.close
		end

	test_zero_quantity_operations
			-- Operations with edge quantities.
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
			l_prod: WMS_PRODUCT
			l_loc: WMS_LOCATION
			l_ignored: BOOLEAN
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-ZERO", "Zero Test")
			l_prod := l_app.create_product ("ZERO-001", "Zero Item", "EA")
			l_loc := l_app.create_location (l_wh.id, "A", "01", "01", "A")

			-- No stock exists initially
			assert_integers_equal ("no_initial", 0, l_app.total_stock_for_product (l_prod.id))

			-- Available for non-existent should be 0
			assert_integers_equal ("no_available", 0, l_app.available_stock_for_product (l_prod.id))

			l_app.close
		end

	test_many_products_one_location
			-- Multiple products at same location.
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
			l_loc: WMS_LOCATION
			l_prod: WMS_PRODUCT
			l_stock_list: ARRAYED_LIST [WMS_STOCK]
			l_ignored: BOOLEAN
			i: INTEGER
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-MANY", "Many Products")
			l_loc := l_app.create_location (l_wh.id, "A", "01", "01", "A")

			-- 20 different products at same location
			from i := 1 until i > 20 loop
				l_prod := l_app.create_product ("MANY-" + i.out, "Product " + i.out, "EA")
				l_ignored := l_app.receive_stock (l_prod.id, l_loc.id, i * 10, "PO-" + i.out, 1)
				i := i + 1
			end

			l_stock_list := l_app.stock_at_location (l_loc.id)
			assert_integers_equal ("twenty_products", 20, l_stock_list.count)

			l_app.close
		end

feature -- Test: Bulk Operations (FRICTION EXPOSURE)

	test_bulk_receive_efficiency
			-- Demonstrates need for bulk upsert API.
			--
			-- FRICTION: Each receive is a separate transaction with potential retry.
			-- For 100 items, this is 100+ round trips to the database.
			--
			-- DESIRED API:
			-- db.upsert_many ("stock",
			--     <<product_id, location_id, quantity>>,
			--     <<"product_id", "location_id">>,
			--     agent increment_quantity)
		local
			l_app: WMS_APP
			l_wh: WMS_WAREHOUSE
			l_loc: WMS_LOCATION
			l_prod: WMS_PRODUCT
			l_ignored: BOOLEAN
			i: INTEGER
		do
			create l_app.make
			l_wh := l_app.create_warehouse ("WH-BULK", "Bulk Test")
			l_loc := l_app.create_location (l_wh.id, "A", "01", "01", "A")

			-- Simulate receiving 100 different products
			-- Currently: 100 individual receive_stock calls
			-- Desired: Single bulk operation
			from i := 1 until i > 100 loop
				l_prod := l_app.create_product ("BULK-" + i.out, "Bulk Product " + i.out, "EA")
				l_ignored := l_app.receive_stock (l_prod.id, l_loc.id, 10, "BULK-PO", 1)
				i := i + 1
			end

			assert_integers_equal ("hundred_products", 100, l_app.stock_at_location (l_loc.id).count)

			l_app.close
		end

feature {NONE} -- Helpers

	assert_integers_equal (a_tag: STRING; a_expected, a_actual: INTEGER)
		do
			assert (a_tag, a_expected = a_actual)
		end

end
