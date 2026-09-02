note
	description: "[
		A development-time monitor that detects N+1 query patterns.
		Normalizes executed SQL into fingerprints, counts repeated patterns, and
		emits warnings when a pattern exceeds a configurable threshold.
		Provides early performance diagnostics for the simple_sql library.
	]"
	purpose: "Detect N+1 query patterns by fingerprinting and counting repeated SQL"
	collaborators: "MML_SEQUENCE, MML_MAP"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_QUERY_MONITOR

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize monitor.
		note
			semantic_role: "[
				Initializes pattern tracking storage
				and sets default detection threshold.
			]"
		do
			create query_patterns.make (20)
			create warnings.make (5)
			threshold := Default_threshold
			is_enabled := True
		ensure
			enabled: is_enabled
			empty_warnings: warnings_model.is_empty
			empty_patterns: query_patterns_model.is_empty
		end

feature -- Access

	warnings: ARRAYED_LIST [STRING_8]
			-- Collected N+1 warnings.

	threshold: INTEGER
			-- Number of similar queries to trigger warning.

	query_count: INTEGER
			-- Total queries recorded.

feature -- Model Queries

	warnings_model: MML_SEQUENCE [STRING_8]
			-- Mathematical model of collected warnings in order.
		note
			semantic_role: "[
				MML specification of warning ordering
				for formal contract verification.
			]"
		do
			create Result
			across warnings as ic loop
				Result := Result & ic
			end
		ensure
			count_matches: Result.count = warnings.count
		end

	query_patterns_model: MML_MAP [STRING_8, INTEGER]
			-- Mathematical model of query pattern counts.
		note
			semantic_role: "[
				MML specification of pattern counts
				for formal contract verification.
			]"
		do
			create Result
			from query_patterns.start until query_patterns.after loop
				Result := Result.updated (query_patterns.key_for_iteration, query_patterns.item_for_iteration)
				query_patterns.forth
			end
		ensure
			count_matches: Result.count = query_patterns.count
		end

feature -- Configuration

	set_threshold (a_threshold: INTEGER)
			-- Set threshold for N+1 detection.
		note
			semantic_role: "[
				Adjusts how many repeated patterns
				trigger an N+1 warning.
			]"
			modifies: "threshold"
		require
			threshold_positive: a_threshold > 1
		do
			threshold := a_threshold
		ensure
			threshold_set: threshold = a_threshold
		end

	enable
			-- Enable monitoring.
		note
			semantic_role: "[
				Activates query recording and pattern
				analysis.
			]"
			modifies: "is_enabled"
		do
			is_enabled := True
		ensure
			enabled: is_enabled
		end

	disable
			-- Disable monitoring.
		note
			semantic_role: "[
				Suspends query recording without
				clearing collected data.
			]"
			modifies: "is_enabled"
		do
			is_enabled := False
		ensure
			disabled: not is_enabled
		end

feature -- Status

	is_enabled: BOOLEAN
			-- Is monitoring active?

	has_warnings: BOOLEAN
			-- Any N+1 warnings detected?
		note
			semantic_role: "[
				Checks whether any repeated query
				patterns exceeded the threshold.
			]"
		do
			Result := not warnings.is_empty
		end

	warning_count: INTEGER
			-- Number of warnings.
		note
			semantic_role: "[
				Returns the count of detected N+1
				pattern violations.
			]"
		do
			Result := warnings.count
		end

feature -- Operations

	record_query (a_sql: READABLE_STRING_8)
			-- Record a query and check for N+1 patterns.
		note
			semantic_role: "[
				Normalizes SQL to a pattern, increments
				its count, and flags threshold breaches.
			]"
			modifies: "query_count, query_patterns, warnings"
		local
			l_pattern: STRING_8
			l_count: INTEGER
		do
			if is_enabled then
				query_count := query_count + 1
				l_pattern := extract_pattern (a_sql)
				if query_patterns.has (l_pattern) then
					l_count := query_patterns.item (l_pattern) + 1
					query_patterns.force (l_count, l_pattern)
					if l_count = threshold then
						add_warning (l_pattern, l_count)
					end
				else
					query_patterns.put (1, l_pattern)
				end
			end
		end

	reset
			-- Clear all recorded data.
		note
			semantic_role: "[
				Clears all pattern counts, warnings,
				and query statistics.
			]"
			modifies: "query_patterns, warnings, query_count"
		do
			query_patterns.wipe_out
			warnings.wipe_out
			query_count := 0
		ensure
			empty: query_count = 0 and warnings.is_empty
			model_warnings_empty: warnings_model.is_empty
			model_patterns_empty: query_patterns_model.is_empty
		end

	report: STRING_8
			-- Generate summary report.
		note
			semantic_role: "[
				Formats a human-readable report of
				query statistics and N+1 warnings.
			]"
		local
			l_sorted: ARRAYED_LIST [TUPLE [pattern: STRING_8; exec_count: INTEGER]]
		do
			create Result.make (500)
			Result.append ("=== Query Monitor Report ===%N")
			Result.append ("Total queries: ")
			Result.append_integer (query_count)
			Result.append ("%N")
			Result.append ("Unique patterns: ")
			Result.append_integer (query_patterns.count)
			Result.append ("%N")

			if has_warnings then
				Result.append ("%N!!! N+1 WARNINGS !!!%N")
				across warnings as ic_w loop
					Result.append ("  - ")
					Result.append (ic_w)
					Result.append ("%N")
				end
			else
				Result.append ("%NNo N+1 issues detected.%N")
			end

			-- Show top repeated queries
			Result.append ("%NTop repeated patterns:%N")
			create l_sorted.make (query_patterns.count)
			from query_patterns.start until query_patterns.after loop
				l_sorted.extend ([query_patterns.key_for_iteration, query_patterns.item_for_iteration])
				query_patterns.forth
			end
			sort_by_count (l_sorted)
			across l_sorted as ic loop
				if ic.exec_count > 1 then
					Result.append ("  ")
					Result.append_integer (ic.exec_count)
					Result.append ("x: ")
					Result.append (ic.pattern.substring (1, ic.pattern.count.min (60)))
					if ic.pattern.count > 60 then
						Result.append ("...")
					end
					Result.append ("%N")
				end
			end
		end

feature {NONE} -- Implementation

	query_patterns: HASH_TABLE [INTEGER, STRING_8]
			-- Query patterns and their counts.

	Default_threshold: INTEGER = 5
			-- Default threshold for N+1 detection.

	extract_pattern (a_sql: READABLE_STRING_8): STRING_8
			-- Extract normalized pattern from SQL.
			-- Replaces literal values with ? placeholders.
		note
			semantic_role: "[
				Normalizes SQL by replacing string
				literals and numbers with ?
				placeholders.
			]"
		local
			i: INTEGER
			c: CHARACTER
			l_in_string: BOOLEAN
			l_in_number: BOOLEAN
		do
			create Result.make (a_sql.count)
			from i := 1 until i > a_sql.count loop
				c := a_sql.item (i)
				if c = '%'' then
					if l_in_string then
						l_in_string := False
						Result.append_character ('?')
					else
						l_in_string := True
					end
				elseif l_in_string then
					-- Skip string content
				elseif c.is_digit and not l_in_number then
					l_in_number := True
					Result.append_character ('?')
				elseif c.is_digit and l_in_number then
					-- Skip digits
				elseif l_in_number and not c.is_digit then
					l_in_number := False
					Result.append_character (c)
				else
					Result.append_character (c)
				end
				i := i + 1
			end
		end

	add_warning (a_pattern: STRING_8; a_count: INTEGER)
			-- Add N+1 warning.
		note
			semantic_role: "[
				Constructs and records a warning message
				for a threshold-exceeding pattern.
			]"
			modifies: "warnings"
		local
			l_msg: STRING_8
		do
			create l_msg.make (100)
			l_msg.append ("N+1 detected: Query pattern executed ")
			l_msg.append_integer (a_count)
			l_msg.append ("+ times: ")
			l_msg.append (a_pattern.substring (1, a_pattern.count.min (80)))
			warnings.extend (l_msg)
		end

	sort_by_count (a_list: ARRAYED_LIST [TUPLE [pattern: STRING_8; exec_count: INTEGER]])
			-- Sort list by exec_count descending (simple bubble sort).
		note
			semantic_role: "[
				Orders pattern-count tuples by execution
				count for report ranking.
			]"
		local
			i, j: INTEGER
			l_temp: TUPLE [pattern: STRING_8; exec_count: INTEGER]
		do
			from i := 1 until i >= a_list.count loop
				from j := i + 1 until j > a_list.count loop
					if a_list [j].exec_count > a_list [i].exec_count then
						l_temp := a_list [i]
						a_list [i] := a_list [j]
						a_list [j] := l_temp
					end
					j := j + 1
				end
				i := i + 1
			end
		end

invariant
	threshold_valid: threshold > 1
	warnings_attached: warnings /= Void
	model_warnings_count: warnings_model.count = warnings.count

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
