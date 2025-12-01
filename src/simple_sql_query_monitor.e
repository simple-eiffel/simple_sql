note
	description: "[
		N+1 Query Detection Monitor.

		Tracks query patterns and warns when potential N+1 problems are detected.
		Enable during development/testing to catch performance issues early.

		Usage:
			db.enable_query_monitor
			-- run your code
			warnings := db.query_monitor.warnings
			db.disable_query_monitor
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_QUERY_MONITOR

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize monitor.
		do
			create query_patterns.make (20)
			create warnings.make (5)
			threshold := Default_threshold
			is_enabled := True
		ensure
			enabled: is_enabled
		end

feature -- Access

	warnings: ARRAYED_LIST [STRING_8]
			-- Collected N+1 warnings.

	threshold: INTEGER
			-- Number of similar queries to trigger warning.

	query_count: INTEGER
			-- Total queries recorded.

feature -- Configuration

	set_threshold (a_threshold: INTEGER)
			-- Set threshold for N+1 detection.
		require
			threshold_positive: a_threshold > 1
		do
			threshold := a_threshold
		ensure
			threshold_set: threshold = a_threshold
		end

	enable
			-- Enable monitoring.
		do
			is_enabled := True
		ensure
			enabled: is_enabled
		end

	disable
			-- Disable monitoring.
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
		do
			Result := not warnings.is_empty
		end

	warning_count: INTEGER
			-- Number of warnings.
		do
			Result := warnings.count
		end

feature -- Operations

	record_query (a_sql: READABLE_STRING_8)
			-- Record a query and check for N+1 patterns.
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
		do
			query_patterns.wipe_out
			warnings.wipe_out
			query_count := 0
		ensure
			empty: query_count = 0 and warnings.is_empty
		end

	report: STRING_8
			-- Generate summary report.
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
				across warnings as w loop
					Result.append ("  - ")
					Result.append (w)
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
		local
			i: INTEGER
			c: CHARACTER
			in_string: BOOLEAN
			in_number: BOOLEAN
		do
			create Result.make (a_sql.count)
			from i := 1 until i > a_sql.count loop
				c := a_sql.item (i)
				if c = '%'' then
					if in_string then
						in_string := False
						Result.append_character ('?')
					else
						in_string := True
					end
				elseif in_string then
					-- Skip string content
				elseif c.is_digit and not in_number then
					in_number := True
					Result.append_character ('?')
				elseif c.is_digit and in_number then
					-- Skip digits
				elseif in_number and not c.is_digit then
					in_number := False
					Result.append_character (c)
				else
					Result.append_character (c)
				end
				i := i + 1
			end
		end

	add_warning (a_pattern: STRING_8; a_count: INTEGER)
			-- Add N+1 warning.
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

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
