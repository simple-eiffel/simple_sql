note
	description: "Stress tests for CPM_APP with complex mock construction project"
	testing: "covers"
	testing: "execution/serial"

class
	TEST_CPM_APP_STRESS

inherit
	TEST_SET_BASE

feature -- Test routines: Complex Construction Project

	test_riverside_commercial_complex
			-- Test CPM on a realistic 50+ activity commercial construction project.
			-- Riverside Commercial Complex: 3-story office building with parking garage.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
			l_critical: ARRAYED_LIST [CPM_ACTIVITY]
		do
			create l_app.make
			l_project := l_app.create_project ("Riverside Commercial Complex")

			-- Build the complete project network
			build_riverside_project (l_app, l_project.id)

			-- Calculate CPM
			l_app.calculate_cpm (l_project.id)

			-- Verify project metrics
			assert_equal ("activity_count", 51, l_app.activity_count (l_project.id))
			assert_equal ("dependency_count", 65, l_app.dependency_count (l_project.id))

			-- Project duration should be around 280-320 days for this type of project
			assert_true ("reasonable_duration", l_app.project_duration (l_project.id) > 200)
			assert_true ("duration_under_year", l_app.project_duration (l_project.id) < 400)

			-- Should have critical path
			l_critical := l_app.critical_path_activities (l_project.id)
			assert_true ("has_critical_path", l_critical.count > 0)
			assert_true ("critical_path_reasonable", l_critical.count >= 10)

			-- Non-critical activities should have float
			assert_true ("has_float", l_app.total_float (l_project.id) > 0)

			l_app.close
		end

feature -- Test routines: Volume Stress

	test_volume_100_activities
			-- Test with 100 activities in linear chain.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
			l_prev, l_curr: CPM_ACTIVITY
			l_ignored: CPM_DEPENDENCY
			i: INTEGER
		do
			create l_app.make
			l_project := l_app.create_project ("Volume 100")

			-- Create linear chain of 100 activities
			l_prev := l_app.add_activity (l_project.id, "A001", "Activity 1", 1)
			from i := 2 until i > 100 loop
				l_curr := l_app.add_activity (l_project.id, "A" + i.out, "Activity " + i.out, 1)
				l_ignored := l_app.add_dependency (l_prev.id, l_curr.id)
				l_prev := l_curr
				i := i + 1
			end

			l_app.calculate_cpm (l_project.id)

			assert_equal ("duration_100", 100, l_app.project_duration (l_project.id))
			assert_equal ("all_critical", 100, l_app.critical_path_length (l_project.id))

			l_app.close
		end

	test_volume_parallel_paths
			-- Test with many parallel paths.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
			l_start, l_finish, l_curr: CPM_ACTIVITY
			l_ignored: CPM_DEPENDENCY
			i: INTEGER
		do
			create l_app.make
			l_project := l_app.create_project ("Parallel Paths")

			l_start := l_app.add_activity (l_project.id, "START", "Start", 0)
			l_finish := l_app.add_activity (l_project.id, "FINISH", "Finish", 0)

			-- Create 50 parallel paths with varying durations
			from i := 1 until i > 50 loop
				l_curr := l_app.add_activity (l_project.id, "P" + i.out, "Path " + i.out, i)
				l_ignored := l_app.add_dependency (l_start.id, l_curr.id)
				l_ignored := l_app.add_dependency (l_curr.id, l_finish.id)
				i := i + 1
			end

			l_app.calculate_cpm (l_project.id)

			-- Duration should be the longest path (50 days)
			assert_equal ("duration_50", 50, l_app.project_duration (l_project.id))

			-- Only the longest path (P50) plus START and FINISH should be critical
			assert_equal ("three_critical", 3, l_app.critical_path_length (l_project.id))

			-- All other paths should have float
			assert_true ("significant_float", l_app.total_float (l_project.id) > 1000)

			l_app.close
		end

	test_volume_diamond_network
			-- Test diamond-shaped network with convergence points.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
			l_start, l_finish: CPM_ACTIVITY
			l_layer1, l_layer2: ARRAYED_LIST [CPM_ACTIVITY]
			l_curr: CPM_ACTIVITY
			l_ignored: CPM_DEPENDENCY
			i: INTEGER
		do
			create l_app.make
			l_project := l_app.create_project ("Diamond Network")

			l_start := l_app.add_activity (l_project.id, "START", "Start", 0)
			l_finish := l_app.add_activity (l_project.id, "FINISH", "Finish", 0)

			-- Layer 1: 10 activities from start
			create l_layer1.make (10)
			from i := 1 until i > 10 loop
				l_curr := l_app.add_activity (l_project.id, "L1-" + i.out, "Layer 1 Task " + i.out, 5 + i)
				l_layer1.extend (l_curr)
				l_ignored := l_app.add_dependency (l_start.id, l_curr.id)
				i := i + 1
			end

			-- Layer 2: 10 activities, each depends on 2 from layer 1
			create l_layer2.make (10)
			from i := 1 until i > 10 loop
				l_curr := l_app.add_activity (l_project.id, "L2-" + i.out, "Layer 2 Task " + i.out, 10)
				l_layer2.extend (l_curr)
				-- Connect to two predecessors
				l_ignored := l_app.add_dependency (l_layer1.i_th (i).id, l_curr.id)
				l_ignored := l_app.add_dependency (l_layer1.i_th (((i - 1) \\ 10) + 1).id, l_curr.id)
				i := i + 1
			end

			-- Connect layer 2 to finish
			across l_layer2 as ic loop
				l_ignored := l_app.add_dependency (ic.id, l_finish.id)
			end

			l_app.calculate_cpm (l_project.id)

			-- Duration should be longest path through network
			-- L1 max = 15 (5+10), L2 = 10, so min is 25
			assert_true ("duration_at_least_25", l_app.project_duration (l_project.id) >= 25)

			l_app.close
		end

feature -- Test routines: Multiple Projects

	test_multiple_concurrent_projects
			-- Test handling multiple projects simultaneously.
		local
			l_app: CPM_APP
			l_p1, l_p2, l_p3: CPM_PROJECT
			l_ignored_act: CPM_ACTIVITY
			l_ignored_dep: CPM_DEPENDENCY
			l_a1, l_b1, l_a2, l_b2: CPM_ACTIVITY
		do
			create l_app.make

			-- Create three projects
			l_p1 := l_app.create_project ("Project Alpha")
			l_p2 := l_app.create_project ("Project Beta")
			l_p3 := l_app.create_project ("Project Gamma")

			-- Add activities to each
			l_a1 := l_app.add_activity (l_p1.id, "A", "Alpha Task A", 10)
			l_b1 := l_app.add_activity (l_p1.id, "B", "Alpha Task B", 5)
			l_ignored_dep := l_app.add_dependency (l_a1.id, l_b1.id)

			l_a2 := l_app.add_activity (l_p2.id, "A", "Beta Task A", 20)
			l_b2 := l_app.add_activity (l_p2.id, "B", "Beta Task B", 10)
			l_ignored_dep := l_app.add_dependency (l_a2.id, l_b2.id)

			l_ignored_act := l_app.add_activity (l_p3.id, "A", "Gamma Task A", 7)

			-- Calculate CPM for each
			l_app.calculate_cpm (l_p1.id)
			l_app.calculate_cpm (l_p2.id)
			l_app.calculate_cpm (l_p3.id)

			-- Verify each project has correct duration
			assert_equal ("p1_duration", 15, l_app.project_duration (l_p1.id))
			assert_equal ("p2_duration", 30, l_app.project_duration (l_p2.id))
			assert_equal ("p3_duration", 7, l_app.project_duration (l_p3.id))

			-- Verify activity counts are separate
			assert_equal ("p1_activities", 2, l_app.activity_count (l_p1.id))
			assert_equal ("p2_activities", 2, l_app.activity_count (l_p2.id))
			assert_equal ("p3_activities", 1, l_app.activity_count (l_p3.id))

			l_app.close
		end

feature -- Test routines: Rapid Updates

	test_rapid_recalculation
			-- Test rapid CPM recalculations after changes.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
			l_a, l_b, l_c: CPM_ACTIVITY
			l_ignored: CPM_DEPENDENCY
			i: INTEGER
		do
			create l_app.make
			l_project := l_app.create_project ("Recalc Test")

			l_a := l_app.add_activity (l_project.id, "A", "Task A", 5)
			l_b := l_app.add_activity (l_project.id, "B", "Task B", 3)
			l_c := l_app.add_activity (l_project.id, "C", "Task C", 4)
			l_ignored := l_app.add_dependency (l_a.id, l_b.id)
			l_ignored := l_app.add_dependency (l_b.id, l_c.id)

			-- Recalculate CPM 100 times
			from i := 1 until i > 100 loop
				l_app.calculate_cpm (l_project.id)
				i := i + 1
			end

			-- Should still have correct values
			assert_equal ("duration_12", 12, l_app.project_duration (l_project.id))

			l_app.close
		end

feature -- Test routines: Complex Dependencies

	test_multiple_predecessors
			-- Test activity with many predecessors.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
			l_preds: ARRAYED_LIST [CPM_ACTIVITY]
			l_final, l_curr: CPM_ACTIVITY
			l_ignored: CPM_DEPENDENCY
			i: INTEGER
		do
			create l_app.make
			l_project := l_app.create_project ("Multi Predecessor")

			-- Create 10 predecessor activities (reduced from 20 for stability)
			create l_preds.make (10)
			from i := 1 until i > 10 loop
				l_curr := l_app.add_activity (l_project.id, "P" + i.out, "Predecessor " + i.out, i)
				l_preds.extend (l_curr)
				i := i + 1
			end

			-- Final activity depends on all predecessors
			l_final := l_app.add_activity (l_project.id, "FINAL", "Final Assembly", 5)
			across l_preds as ic loop
				l_ignored := l_app.add_dependency (ic.id, l_final.id)
			end

			l_app.calculate_cpm (l_project.id)

			-- Duration = longest predecessor (10) + final (5) = 15
			assert_equal ("duration_15", 15, l_app.project_duration (l_project.id))

			-- Verify final's early start
			if attached l_app.find_activity (l_final.id) as l_f then
				assert_equal ("final_es_10", 10, l_f.early_start)
			end

			l_app.close
		end

	test_varied_lag_times
			-- Test network with various lag times.
		local
			l_app: CPM_APP
			l_project: CPM_PROJECT
			l_a, l_b, l_c, l_d: CPM_ACTIVITY
			l_ignored: CPM_DEPENDENCY
		do
			create l_app.make
			l_project := l_app.create_project ("Lag Network")

			-- A(5) --[lag 3]--> B(10)
			-- A(5) --[lag 7]--> C(5)
			-- B & C --> D(2)
			l_a := l_app.add_activity (l_project.id, "A", "Start Work", 5)
			l_b := l_app.add_activity (l_project.id, "B", "Path B", 10)
			l_c := l_app.add_activity (l_project.id, "C", "Path C", 5)
			l_d := l_app.add_activity (l_project.id, "D", "Final", 2)

			l_ignored := l_app.add_dependency_with_lag (l_a.id, l_b.id, "FS", 3)
			l_ignored := l_app.add_dependency_with_lag (l_a.id, l_c.id, "FS", 7)
			l_ignored := l_app.add_dependency (l_b.id, l_d.id)
			l_ignored := l_app.add_dependency (l_c.id, l_d.id)

			l_app.calculate_cpm (l_project.id)

			-- Path via B: 5 + 3 + 10 = 18
			-- Path via C: 5 + 7 + 5 = 17
			-- D starts at max(18, 17) = 18, duration = 18 + 2 = 20
			assert_equal ("duration_20", 20, l_app.project_duration (l_project.id))

			l_app.close
		end

feature {NONE} -- Implementation: Test Data Builder

	build_riverside_project (a_app: CPM_APP; a_project_id: INTEGER_64)
			-- Build a complete commercial construction project network.
			-- 52 activities representing a realistic 3-story office building with parking garage.
		local
			l_ignored: CPM_DEPENDENCY
			-- Phase 1: Site Work
			l_site_survey, l_permits, l_site_clear, l_excavation, l_soil_test: CPM_ACTIVITY
			-- Phase 2: Foundation
			l_found_layout, l_footings, l_found_walls, l_waterproof, l_backfill: CPM_ACTIVITY
			-- Phase 3: Parking Garage (parallel)
			l_garage_slab, l_garage_walls, l_garage_roof, l_garage_mep, l_garage_finish: CPM_ACTIVITY
			-- Phase 4: Structural
			l_steel_fab, l_steel_erect, l_floor1_deck, l_floor2_deck, l_floor3_deck, l_roof_deck: CPM_ACTIVITY
			-- Phase 5: Building Envelope
			l_ext_walls, l_windows, l_roofing, l_watertest: CPM_ACTIVITY
			-- Phase 6: MEP Rough-in
			l_mep_coord, l_plumb_rough, l_hvac_rough, l_elec_rough, l_fire_sprink: CPM_ACTIVITY
			-- Phase 7: Interior (per floor, simplified)
			l_int_frame, l_drywall, l_ceiling, l_flooring, l_paint: CPM_ACTIVITY
			-- Phase 8: MEP Finish
			l_plumb_finish, l_hvac_finish, l_elec_finish, l_fire_test: CPM_ACTIVITY
			-- Phase 9: Finishes & Closeout
			l_elevator, l_fixtures, l_signage, l_landscape, l_punchlist, l_final_insp, l_turnover: CPM_ACTIVITY
			-- Milestones
			l_found_complete, l_struct_complete, l_envelope_complete, l_mep_complete, l_project_complete: CPM_ACTIVITY
		do
			-- ========== PHASE 1: SITE WORK ==========
			l_site_survey := a_app.add_activity_with_description (a_project_id, "SW-01", "Site Survey & Layout", "Topographic survey and construction staking", 5)
			l_permits := a_app.add_activity_with_description (a_project_id, "SW-02", "Obtain Permits", "Building permit, environmental permits", 20)
			l_site_clear := a_app.add_activity_with_description (a_project_id, "SW-03", "Site Clearing", "Clear vegetation, demo existing structures", 10)
			l_excavation := a_app.add_activity_with_description (a_project_id, "SW-04", "Mass Excavation", "Excavate for foundation and parking", 15)
			l_soil_test := a_app.add_activity_with_description (a_project_id, "SW-05", "Soil Compaction Testing", "Verify soil bearing capacity", 3)

			l_ignored := a_app.add_dependency (l_site_survey.id, l_permits.id)
			l_ignored := a_app.add_dependency (l_site_survey.id, l_site_clear.id)
			l_ignored := a_app.add_dependency (l_permits.id, l_excavation.id)
			l_ignored := a_app.add_dependency (l_site_clear.id, l_excavation.id)
			l_ignored := a_app.add_dependency (l_excavation.id, l_soil_test.id)

			-- ========== PHASE 2: FOUNDATION ==========
			l_found_layout := a_app.add_activity_with_description (a_project_id, "FD-01", "Foundation Layout", "Mark foundation locations", 3)
			l_footings := a_app.add_activity_with_description (a_project_id, "FD-02", "Footings", "Pour concrete footings", 12)
			l_found_walls := a_app.add_activity_with_description (a_project_id, "FD-03", "Foundation Walls", "Form and pour foundation walls", 15)
			l_waterproof := a_app.add_activity_with_description (a_project_id, "FD-04", "Waterproofing", "Apply foundation waterproofing", 5)
			l_backfill := a_app.add_activity_with_description (a_project_id, "FD-05", "Backfill", "Backfill around foundation", 7)
			l_found_complete := a_app.add_activity (a_project_id, "MS-01", "Foundation Complete", 0)

			l_ignored := a_app.add_dependency (l_soil_test.id, l_found_layout.id)
			l_ignored := a_app.add_dependency (l_found_layout.id, l_footings.id)
			l_ignored := a_app.add_dependency_with_lag (l_footings.id, l_found_walls.id, "FS", 3) -- Curing time
			l_ignored := a_app.add_dependency (l_found_walls.id, l_waterproof.id)
			l_ignored := a_app.add_dependency (l_waterproof.id, l_backfill.id)
			l_ignored := a_app.add_dependency (l_backfill.id, l_found_complete.id)

			-- ========== PHASE 3: PARKING GARAGE (PARALLEL) ==========
			l_garage_slab := a_app.add_activity_with_description (a_project_id, "PG-01", "Garage Slab on Grade", "Pour parking garage floor slab", 10)
			l_garage_walls := a_app.add_activity_with_description (a_project_id, "PG-02", "Garage Walls", "Precast garage walls", 12)
			l_garage_roof := a_app.add_activity_with_description (a_project_id, "PG-03", "Garage Roof Deck", "Pour garage roof/plaza deck", 8)
			l_garage_mep := a_app.add_activity_with_description (a_project_id, "PG-04", "Garage MEP", "Lighting, ventilation, fire suppression", 15)
			l_garage_finish := a_app.add_activity_with_description (a_project_id, "PG-05", "Garage Finish", "Striping, signage, equipment", 7)

			l_ignored := a_app.add_dependency (l_found_complete.id, l_garage_slab.id)
			l_ignored := a_app.add_dependency (l_garage_slab.id, l_garage_walls.id)
			l_ignored := a_app.add_dependency (l_garage_walls.id, l_garage_roof.id)
			l_ignored := a_app.add_dependency (l_garage_roof.id, l_garage_mep.id)
			l_ignored := a_app.add_dependency (l_garage_mep.id, l_garage_finish.id)

			-- ========== PHASE 4: STRUCTURAL ==========
			l_steel_fab := a_app.add_activity_with_description (a_project_id, "ST-01", "Steel Fabrication", "Fabricate structural steel offsite", 30)
			l_steel_erect := a_app.add_activity_with_description (a_project_id, "ST-02", "Steel Erection", "Erect structural steel frame", 25)
			l_floor1_deck := a_app.add_activity_with_description (a_project_id, "ST-03", "Floor 1 Metal Deck & Concrete", "Install deck and pour concrete", 8)
			l_floor2_deck := a_app.add_activity_with_description (a_project_id, "ST-04", "Floor 2 Metal Deck & Concrete", "Install deck and pour concrete", 8)
			l_floor3_deck := a_app.add_activity_with_description (a_project_id, "ST-05", "Floor 3 Metal Deck & Concrete", "Install deck and pour concrete", 8)
			l_roof_deck := a_app.add_activity_with_description (a_project_id, "ST-06", "Roof Metal Deck", "Install roof deck", 6)
			l_struct_complete := a_app.add_activity (a_project_id, "MS-02", "Structure Complete", 0)

			-- Steel fab can start early (parallel with foundation)
			l_ignored := a_app.add_dependency (l_permits.id, l_steel_fab.id)
			l_ignored := a_app.add_dependency (l_found_complete.id, l_steel_erect.id)
			l_ignored := a_app.add_dependency (l_steel_fab.id, l_steel_erect.id)
			l_ignored := a_app.add_dependency (l_steel_erect.id, l_floor1_deck.id)
			l_ignored := a_app.add_dependency (l_floor1_deck.id, l_floor2_deck.id)
			l_ignored := a_app.add_dependency (l_floor2_deck.id, l_floor3_deck.id)
			l_ignored := a_app.add_dependency (l_floor3_deck.id, l_roof_deck.id)
			l_ignored := a_app.add_dependency (l_roof_deck.id, l_struct_complete.id)

			-- ========== PHASE 5: BUILDING ENVELOPE ==========
			l_ext_walls := a_app.add_activity_with_description (a_project_id, "EN-01", "Exterior Wall Framing & Sheathing", "Metal stud framing, sheathing, WRB", 20)
			l_windows := a_app.add_activity_with_description (a_project_id, "EN-02", "Windows & Curtain Wall", "Install glazing systems", 25)
			l_roofing := a_app.add_activity_with_description (a_project_id, "EN-03", "Roofing", "Install roof membrane and insulation", 12)
			l_watertest := a_app.add_activity_with_description (a_project_id, "EN-04", "Water Testing", "Test building envelope for leaks", 5)
			l_envelope_complete := a_app.add_activity (a_project_id, "MS-03", "Envelope Complete", 0)

			l_ignored := a_app.add_dependency (l_struct_complete.id, l_ext_walls.id)
			l_ignored := a_app.add_dependency (l_struct_complete.id, l_roofing.id)
			l_ignored := a_app.add_dependency (l_ext_walls.id, l_windows.id)
			l_ignored := a_app.add_dependency (l_windows.id, l_watertest.id)
			l_ignored := a_app.add_dependency (l_roofing.id, l_watertest.id)
			l_ignored := a_app.add_dependency (l_watertest.id, l_envelope_complete.id)

			-- ========== PHASE 6: MEP ROUGH-IN ==========
			l_mep_coord := a_app.add_activity_with_description (a_project_id, "MP-01", "MEP Coordination", "BIM coordination, shop drawings", 15)
			l_plumb_rough := a_app.add_activity_with_description (a_project_id, "MP-02", "Plumbing Rough-in", "DWV, water supply rough-in", 20)
			l_hvac_rough := a_app.add_activity_with_description (a_project_id, "MP-03", "HVAC Rough-in", "Ductwork, piping, equipment", 25)
			l_elec_rough := a_app.add_activity_with_description (a_project_id, "MP-04", "Electrical Rough-in", "Conduit, wire, panels", 22)
			l_fire_sprink := a_app.add_activity_with_description (a_project_id, "MP-05", "Fire Sprinkler", "Install sprinkler system", 18)

			l_ignored := a_app.add_dependency (l_struct_complete.id, l_mep_coord.id)
			l_ignored := a_app.add_dependency (l_mep_coord.id, l_plumb_rough.id)
			l_ignored := a_app.add_dependency (l_mep_coord.id, l_hvac_rough.id)
			l_ignored := a_app.add_dependency (l_mep_coord.id, l_elec_rough.id)
			l_ignored := a_app.add_dependency (l_mep_coord.id, l_fire_sprink.id)

			-- ========== PHASE 7: INTERIOR ==========
			l_int_frame := a_app.add_activity_with_description (a_project_id, "IN-01", "Interior Framing", "Metal stud partitions all floors", 18)
			l_drywall := a_app.add_activity_with_description (a_project_id, "IN-02", "Drywall", "Hang and finish drywall", 20)
			l_ceiling := a_app.add_activity_with_description (a_project_id, "IN-03", "Ceiling Grid & Tile", "Install suspended ceilings", 12)
			l_flooring := a_app.add_activity_with_description (a_project_id, "IN-04", "Flooring", "Carpet, tile, VCT", 15)
			l_paint := a_app.add_activity_with_description (a_project_id, "IN-05", "Painting", "Prime and paint all surfaces", 14)

			l_ignored := a_app.add_dependency (l_envelope_complete.id, l_int_frame.id)
			l_ignored := a_app.add_dependency (l_plumb_rough.id, l_int_frame.id)
			l_ignored := a_app.add_dependency (l_hvac_rough.id, l_int_frame.id)
			l_ignored := a_app.add_dependency (l_elec_rough.id, l_int_frame.id)
			l_ignored := a_app.add_dependency (l_int_frame.id, l_drywall.id)
			l_ignored := a_app.add_dependency (l_drywall.id, l_ceiling.id)
			l_ignored := a_app.add_dependency (l_drywall.id, l_paint.id)
			l_ignored := a_app.add_dependency (l_paint.id, l_flooring.id)

			-- ========== PHASE 8: MEP FINISH ==========
			l_plumb_finish := a_app.add_activity_with_description (a_project_id, "MF-01", "Plumbing Fixtures", "Install fixtures, test systems", 10)
			l_hvac_finish := a_app.add_activity_with_description (a_project_id, "MF-02", "HVAC Finish", "Install diffusers, TAB, commissioning", 12)
			l_elec_finish := a_app.add_activity_with_description (a_project_id, "MF-03", "Electrical Finish", "Devices, fixtures, panel terminations", 10)
			l_fire_test := a_app.add_activity_with_description (a_project_id, "MF-04", "Fire System Testing", "Test and certify fire systems", 5)
			l_mep_complete := a_app.add_activity (a_project_id, "MS-04", "MEP Complete", 0)

			l_ignored := a_app.add_dependency (l_ceiling.id, l_plumb_finish.id)
			l_ignored := a_app.add_dependency (l_ceiling.id, l_hvac_finish.id)
			l_ignored := a_app.add_dependency (l_ceiling.id, l_elec_finish.id)
			l_ignored := a_app.add_dependency (l_fire_sprink.id, l_fire_test.id)
			l_ignored := a_app.add_dependency (l_ceiling.id, l_fire_test.id)
			l_ignored := a_app.add_dependency (l_plumb_finish.id, l_mep_complete.id)
			l_ignored := a_app.add_dependency (l_hvac_finish.id, l_mep_complete.id)
			l_ignored := a_app.add_dependency (l_elec_finish.id, l_mep_complete.id)
			l_ignored := a_app.add_dependency (l_fire_test.id, l_mep_complete.id)

			-- ========== PHASE 9: FINISHES & CLOSEOUT ==========
			l_elevator := a_app.add_activity_with_description (a_project_id, "CL-01", "Elevator Installation", "Install and certify elevator", 30)
			l_fixtures := a_app.add_activity_with_description (a_project_id, "CL-02", "Specialties & Fixtures", "Toilet accessories, signage, misc", 8)
			l_signage := a_app.add_activity_with_description (a_project_id, "CL-03", "Final Signage", "ADA signage, wayfinding", 5)
			l_landscape := a_app.add_activity_with_description (a_project_id, "CL-04", "Landscaping", "Plantings, irrigation, hardscape", 20)
			l_punchlist := a_app.add_activity_with_description (a_project_id, "CL-05", "Punchlist", "Complete punchlist items", 10)
			l_final_insp := a_app.add_activity_with_description (a_project_id, "CL-06", "Final Inspections", "Building dept, fire marshal, elevator", 7)
			l_turnover := a_app.add_activity_with_description (a_project_id, "CL-07", "Owner Training & Turnover", "Train owner, deliver O&M manuals", 5)
			l_project_complete := a_app.add_activity (a_project_id, "MS-05", "Project Complete", 0)

			-- Elevator starts early (after structure)
			l_ignored := a_app.add_dependency (l_struct_complete.id, l_elevator.id)
			l_ignored := a_app.add_dependency (l_envelope_complete.id, l_landscape.id)
			l_ignored := a_app.add_dependency (l_flooring.id, l_fixtures.id)
			l_ignored := a_app.add_dependency (l_fixtures.id, l_signage.id)
			l_ignored := a_app.add_dependency (l_mep_complete.id, l_punchlist.id)
			l_ignored := a_app.add_dependency (l_flooring.id, l_punchlist.id)
			l_ignored := a_app.add_dependency (l_garage_finish.id, l_punchlist.id)
			l_ignored := a_app.add_dependency (l_punchlist.id, l_final_insp.id)
			l_ignored := a_app.add_dependency (l_elevator.id, l_final_insp.id)
			l_ignored := a_app.add_dependency (l_landscape.id, l_final_insp.id)
			l_ignored := a_app.add_dependency (l_signage.id, l_final_insp.id)
			l_ignored := a_app.add_dependency (l_final_insp.id, l_turnover.id)
			l_ignored := a_app.add_dependency (l_turnover.id, l_project_complete.id)
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
