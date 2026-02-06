note
	description: "[
		WMS Profile Application - Exercises WMS code paths for profiling.

		This is a silent, non-interactive workload that hammers the WMS code
		to generate profiling data. It mimics realistic warehouse operations
		without assertions or user interaction.

		Run this target (wms_profile) to generate profinfo data, then use
		EiffelStudio's Profiler Wizard to analyze the results.
	]"

class
	WMS_PROFILE_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run the profile workload.
		do
			print ("WMS Profile Workload Starting...%N")

			create wms.make

			run_warehouse_setup
			run_product_setup
			run_location_setup
			run_stock_operations
			run_reservation_operations
			run_query_operations

			wms.close

			print ("WMS Profile Workload Complete.%N")
		end

feature {NONE} -- Implementation

	wms: WMS_APP

	-- Cached IDs for operations
	warehouse_id: INTEGER_64
	product_ids: ARRAYED_LIST [INTEGER_64]
	location_ids: ARRAYED_LIST [INTEGER_64]

feature {NONE} -- Workload Phases

	run_warehouse_setup
			-- Create warehouses.
		local
			l_w: WMS_WAREHOUSE
			i: INTEGER
		do
			print ("  Creating warehouses...%N")
			from i := 1 until i > 5 loop
				l_w := wms.create_warehouse ("WH" + i.out, "Warehouse " + i.out)
				if i = 1 then
					warehouse_id := l_w.id
				end
				i := i + 1
			end
		end

	run_product_setup
			-- Create products.
		local
			l_p: WMS_PRODUCT
			i: INTEGER
		do
			print ("  Creating products...%N")
			create product_ids.make (100)
			from i := 1 until i > 100 loop
				l_p := wms.create_product ("SKU" + i.out.to_string_8.to_string_8, "Product " + i.out, "EA")
				product_ids.extend (l_p.id)
				i := i + 1
			end
		end

	run_location_setup
			-- Create locations in first warehouse.
		local
			l_loc: WMS_LOCATION
			aisle, rack, shelf, bin: INTEGER
		do
			print ("  Creating locations...%N")
			create location_ids.make (200)
			from aisle := 1 until aisle > 5 loop
				from rack := 1 until rack > 4 loop
					from shelf := 1 until shelf > 5 loop
						from bin := 1 until bin > 2 loop
							l_loc := wms.create_location (warehouse_id,
								"A" + aisle.out,
								"R" + rack.out,
								"S" + shelf.out,
								"B" + bin.out)
							location_ids.extend (l_loc.id)
							bin := bin + 1
						end
						shelf := shelf + 1
					end
					rack := rack + 1
				end
				aisle := aisle + 1
			end
		end

	run_stock_operations
			-- Receive and transfer stock - the heavy lifting.
		local
			i, j, loc_idx: INTEGER
			l_success: BOOLEAN
			product_id, from_loc, to_loc: INTEGER_64
		do
			print ("  Running stock operations...%N")

			-- Receive stock for each product at random locations
			print ("    Receiving stock...%N")
			from i := 1 until i > product_ids.count loop
				product_id := product_ids [i]
				-- Receive at 3 different locations per product
				from j := 1 until j > 3 loop
					loc_idx := ((i * 7 + j * 13) \\ location_ids.count) + 1
					l_success := wms.receive_stock (product_id, location_ids [loc_idx], 100 + (i * j), "RCV-" + i.out + "-" + j.out, 1)
					j := j + 1
				end
				i := i + 1
			end

			-- Transfer stock between locations
			print ("    Transferring stock...%N")
			from i := 1 until i > 50 loop
				product_id := product_ids [((i * 3) \\ product_ids.count) + 1]
				from_loc := location_ids [((i * 5) \\ location_ids.count) + 1]
				to_loc := location_ids [((i * 7 + 1) \\ location_ids.count) + 1]
				if from_loc /= to_loc then
					l_success := wms.transfer_stock (product_id, from_loc, to_loc, 10, "TRF-" + i.out, 1)
				end
				i := i + 1
			end
		end

	run_reservation_operations
			-- Create and release reservations.
		local
			i, loc_idx: INTEGER
			l_product_id: INTEGER_64
			l_res: detachable WMS_RESERVATION
			l_success: BOOLEAN
			l_reservation_ids: ARRAYED_LIST [INTEGER_64]
		do
			print ("  Running reservation operations...%N")
			create l_reservation_ids.make (30)

			-- Create reservations
			print ("    Creating reservations...%N")
			from i := 1 until i > 30 loop
				l_product_id := product_ids [((i * 11) \\ product_ids.count) + 1]
				loc_idx := ((i * 13) \\ location_ids.count) + 1
				l_res := wms.reserve_stock (l_product_id, location_ids [loc_idx], 5, "ORD-" + i.out, 1, 60)
				if attached l_res then
					l_reservation_ids.extend (l_res.id)
				end
				i := i + 1
			end

			-- Release half of them
			print ("    Releasing reservations...%N")
			from i := 1 until i > l_reservation_ids.count // 2 loop
				l_success := wms.release_reservation (l_reservation_ids [i])
				i := i + 1
			end

			-- Cleanup expired (none should be expired, but exercises the code)
			i := wms.cleanup_expired_reservations
		end

	run_query_operations
			-- Run various queries to exercise read paths.
		local
			i: INTEGER
			l_warehouses: ARRAYED_LIST [WMS_WAREHOUSE]
			l_locations: ARRAYED_LIST [WMS_LOCATION]
			l_stock_list: ARRAYED_LIST [WMS_STOCK]
			l_movements: ARRAYED_LIST [WMS_MOVEMENT]
			l_reservations: ARRAYED_LIST [WMS_RESERVATION]
			l_low_stock: ARRAYED_LIST [TUPLE [product: WMS_PRODUCT; total: INTEGER; min: INTEGER]]
			total, available: INTEGER
			l_w: detachable WMS_WAREHOUSE
			l_p: detachable WMS_PRODUCT
			l_loc: detachable WMS_LOCATION
		do
			print ("  Running query operations...%N")

			-- Query all warehouses
			l_warehouses := wms.all_warehouses

			-- Query locations for each warehouse
			across l_warehouses as wh loop
				l_locations := wms.warehouse_locations (wh.id)
			end

			-- Find operations
			from i := 1 until i > 20 loop
				l_w := wms.find_warehouse (i.to_integer_64)
				l_p := wms.find_product (product_ids [((i * 3) \\ product_ids.count) + 1])
				l_loc := wms.find_location (location_ids [((i * 5) \\ location_ids.count) + 1])
				i := i + 1
			end

			-- Stock queries
			from i := 1 until i > 50 loop
				l_stock_list := wms.stock_at_location (location_ids [((i * 7) \\ location_ids.count) + 1])
				total := wms.total_stock_for_product (product_ids [((i * 3) \\ product_ids.count) + 1])
				available := wms.available_stock_for_product (product_ids [((i * 5) \\ product_ids.count) + 1])
				i := i + 1
			end

			-- Movement queries
			from i := 1 until i > 30 loop
				l_movements := wms.movements_for_product (product_ids [((i * 11) \\ product_ids.count) + 1], 20)
				l_movements := wms.movements_at_location (location_ids [((i * 13) \\ location_ids.count) + 1], 20)
				i := i + 1
			end

			-- Reservation queries
			from i := 1 until i > 20 loop
				l_reservations := wms.reservations_for_order ("ORD-" + i.out)
				i := i + 1
			end

			-- Low stock report
			l_low_stock := wms.products_below_min_stock
		end

end
