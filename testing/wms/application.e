note
	description: "Test application root class for wms tests: runs every test through EQA_TEST_EVALUATOR"
	date: "$Date$"
	revision: "$Revision$"

class
	APPLICATION

create
	make

feature -- Initialization

	make
			-- Run every wms test and print a summary.
		do
			run_test_wms_app
			run_test_wms_stress
			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")
		end

feature {NONE} -- Runners

	run_test_wms_app
		local
			l_eval: EQA_TEST_EVALUATOR [TEST_WMS_APP]
		do
			create l_eval
			report ("TEST_WMS_APP.test_create_warehouse", l_eval.execute (agent {TEST_WMS_APP}.test_create_warehouse))
			report ("TEST_WMS_APP.test_find_warehouse", l_eval.execute (agent {TEST_WMS_APP}.test_find_warehouse))
			report ("TEST_WMS_APP.test_create_product", l_eval.execute (agent {TEST_WMS_APP}.test_create_product))
			report ("TEST_WMS_APP.test_find_product_by_sku", l_eval.execute (agent {TEST_WMS_APP}.test_find_product_by_sku))
			report ("TEST_WMS_APP.test_create_location", l_eval.execute (agent {TEST_WMS_APP}.test_create_location))
			report ("TEST_WMS_APP.test_warehouse_locations", l_eval.execute (agent {TEST_WMS_APP}.test_warehouse_locations))
			report ("TEST_WMS_APP.test_receive_stock", l_eval.execute (agent {TEST_WMS_APP}.test_receive_stock))
			report ("TEST_WMS_APP.test_receive_stock_adds_to_existing", l_eval.execute (agent {TEST_WMS_APP}.test_receive_stock_adds_to_existing))
			report ("TEST_WMS_APP.test_transfer_stock", l_eval.execute (agent {TEST_WMS_APP}.test_transfer_stock))
			report ("TEST_WMS_APP.test_transfer_insufficient_stock", l_eval.execute (agent {TEST_WMS_APP}.test_transfer_insufficient_stock))
			report ("TEST_WMS_APP.test_total_stock_for_product", l_eval.execute (agent {TEST_WMS_APP}.test_total_stock_for_product))
			report ("TEST_WMS_APP.test_reserve_stock", l_eval.execute (agent {TEST_WMS_APP}.test_reserve_stock))
			report ("TEST_WMS_APP.test_reserve_insufficient_available", l_eval.execute (agent {TEST_WMS_APP}.test_reserve_insufficient_available))
			report ("TEST_WMS_APP.test_release_reservation", l_eval.execute (agent {TEST_WMS_APP}.test_release_reservation))
			report ("TEST_WMS_APP.test_movements_recorded", l_eval.execute (agent {TEST_WMS_APP}.test_movements_recorded))
			report ("TEST_WMS_APP.test_products_below_min_stock", l_eval.execute (agent {TEST_WMS_APP}.test_products_below_min_stock))
		end

	run_test_wms_stress
		local
			l_eval: EQA_TEST_EVALUATOR [TEST_WMS_STRESS]
		do
			create l_eval
			report ("TEST_WMS_STRESS.test_many_sequential_receives", l_eval.execute (agent {TEST_WMS_STRESS}.test_many_sequential_receives))
			report ("TEST_WMS_STRESS.test_transfer_chain", l_eval.execute (agent {TEST_WMS_STRESS}.test_transfer_chain))
			report ("TEST_WMS_STRESS.test_reserve_exact_available", l_eval.execute (agent {TEST_WMS_STRESS}.test_reserve_exact_available))
			report ("TEST_WMS_STRESS.test_multiple_reservations_same_stock", l_eval.execute (agent {TEST_WMS_STRESS}.test_multiple_reservations_same_stock))
			report ("TEST_WMS_STRESS.test_movement_audit_completeness", l_eval.execute (agent {TEST_WMS_STRESS}.test_movement_audit_completeness))
			report ("TEST_WMS_STRESS.test_transfer_all_stock", l_eval.execute (agent {TEST_WMS_STRESS}.test_transfer_all_stock))
			report ("TEST_WMS_STRESS.test_zero_quantity_operations", l_eval.execute (agent {TEST_WMS_STRESS}.test_zero_quantity_operations))
			report ("TEST_WMS_STRESS.test_many_products_one_location", l_eval.execute (agent {TEST_WMS_STRESS}.test_many_products_one_location))
			report ("TEST_WMS_STRESS.test_bulk_receive_efficiency", l_eval.execute (agent {TEST_WMS_STRESS}.test_bulk_receive_efficiency))
		end

feature {NONE} -- Implementation

	passed, failed: INTEGER

	report (a_name: STRING_8; a_result: EQA_PARTIAL_RESULT)
			-- Count and print the outcome of test `a_name'.
		do
			if a_result.is_pass then
				passed := passed + 1
				print ("  PASS: " + a_name + "%N")
			else
				failed := failed + 1
				print ("  FAIL: " + a_name)
				if attached {EQA_RESULT} a_result as l_full and then attached l_full.test_response.exception as l_ex then
					print (" [" + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (l_ex.tag_name) + "]")
				end
				print ("%N")
			end
		end

end
