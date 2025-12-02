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
			w: WMS_WAREHOUSE
			i: INTEGER
		do
			print ("  Creating warehouses...%N")
			from i := 1 until i > 5 loop
				w := wms.create_warehouse ("WH" + i.out, "Warehouse " + i.out)
				if i = 1 then
					warehouse_id := w.id
				end
				i := i + 1
			end
		end

	run_product_setup
			-- Create products.
		local
			p: WMS_PRODUCT
			i: INTEGER
		do
			print ("  Creating products...%N")
			create product_ids.make (100)
			from i := 1 until i > 100 loop
				p := wms.create_product ("SKU" + i.out.as_string_8.to_string_8, "Product " + i.out, "EA")
				product_ids.extend (p.id)
				i := i + 1
			end
		end

	run_location_setup
			-- Create locations in first warehouse.
		local
			loc: WMS_LOCATION
			aisle, rack, shelf, bin: INTEGER
		do
			print ("  Creating locations...%N")
			create location_ids.make (200)
			from aisle := 1 until aisle > 5 loop
				from rack := 1 until rack > 4 loop
					from shelf := 1 until shelf > 5 loop
						from bin := 1 until bin > 2 loop
							loc := wms.create_location (warehouse_id,
								"A" + aisle.out,
								"R" + rack.out,
								"S" + shelf.out,
								"B" + bin.out)
							location_ids.extend (loc.id)
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
			success: BOOLEAN
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
					success := wms.receive_stock (product_id, location_ids [loc_idx], 100 + (i * j), "RCV-" + i.out + "-" + j.out, 1)
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
					success := wms.transfer_stock (product_id, from_loc, to_loc, 10, "TRF-" + i.out, 1)
				end
				i := i + 1
			end
		end

	run_reservation_operations
			-- Create and release reservations.
		local
			i, loc_idx: INTEGER
			product_id: INTEGER_64
			res: detachable WMS_RESERVATION
			success: BOOLEAN
			reservation_ids: ARRAYED_LIST [INTEGER_64]
		do
			print ("  Running reservation operations...%N")
			create reservation_ids.make (30)

			-- Create reservations
			print ("    Creating reservations...%N")
			from i := 1 until i > 30 loop
				product_id := product_ids [((i * 11) \\ product_ids.count) + 1]
				loc_idx := ((i * 13) \\ location_ids.count) + 1
				res := wms.reserve_stock (product_id, location_ids [loc_idx], 5, "ORD-" + i.out, 1, 60)
				if attached res then
					reservation_ids.extend (res.id)
				end
				i := i + 1
			end

			-- Release half of them
			print ("    Releasing reservations...%N")
			from i := 1 until i > reservation_ids.count // 2 loop
				success := wms.release_reservation (reservation_ids [i])
				i := i + 1
			end

			-- Cleanup expired (none should be expired, but exercises the code)
			i := wms.cleanup_expired_reservations
		end

	run_query_operations
			-- Run various queries to exercise read paths.
		local
			i: INTEGER
			warehouses: ARRAYED_LIST [WMS_WAREHOUSE]
			locations: ARRAYED_LIST [WMS_LOCATION]
			stock_list: ARRAYED_LIST [WMS_STOCK]
			movements: ARRAYED_LIST [WMS_MOVEMENT]
			reservations: ARRAYED_LIST [WMS_RESERVATION]
			low_stock: ARRAYED_LIST [TUPLE [product: WMS_PRODUCT; total: INTEGER; min: INTEGER]]
			total, available: INTEGER
			w: detachable WMS_WAREHOUSE
			p: detachable WMS_PRODUCT
			loc: detachable WMS_LOCATION
		do
			print ("  Running query operations...%N")

			-- Query all warehouses
			warehouses := wms.all_warehouses

			-- Query locations for each warehouse
			across warehouses as wh loop
				locations := wms.warehouse_locations (wh.id)
			end

			-- Find operations
			from i := 1 until i > 20 loop
				w := wms.find_warehouse (i.to_integer_64)
				p := wms.find_product (product_ids [((i * 3) \\ product_ids.count) + 1])
				loc := wms.find_location (location_ids [((i * 5) \\ location_ids.count) + 1])
				i := i + 1
			end

			-- Stock queries
			from i := 1 until i > 50 loop
				stock_list := wms.stock_at_location (location_ids [((i * 7) \\ location_ids.count) + 1])
				total := wms.total_stock_for_product (product_ids [((i * 3) \\ product_ids.count) + 1])
				available := wms.available_stock_for_product (product_ids [((i * 5) \\ product_ids.count) + 1])
				i := i + 1
			end

			-- Movement queries
			from i := 1 until i > 30 loop
				movements := wms.movements_for_product (product_ids [((i * 11) \\ product_ids.count) + 1], 20)
				movements := wms.movements_at_location (location_ids [((i * 13) \\ location_ids.count) + 1], 20)
				i := i + 1
			end

			-- Reservation queries
			from i := 1 until i > 20 loop
				reservations := wms.reservations_for_order ("ORD-" + i.out)
				i := i + 1
			end

			-- Low stock report
			low_stock := wms.products_below_min_stock
		end

end
