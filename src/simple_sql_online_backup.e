note
	description: "[
		An online backup controller wrapping the SQLite Backup API.
		Copies source database pages to a destination incrementally or in one shot,
		with optional progress callbacks and throttling.
		Provides contract-driven hot-backup capability for the simple_sql library.
	]"
	purpose: "Perform live database backups with progress monitoring for SQLite databases"
	collaborators: "SIMPLE_SQL_DATABASE, SQLITE_BACKUP_EXTERNALS"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_ONLINE_BACKUP

inherit
	SQLITE_BACKUP_EXTERNALS
		rename
			Sqlite_ok as Backup_ok,
			Sqlite_done as Backup_done
		end

create
	make,
	make_to_file,
	make_from_file

feature {NONE} -- Initialization

	make (a_source, a_destination: SIMPLE_SQL_DATABASE)
			-- Initialize backup from `a_source` to `a_destination`
		note
			semantic_role: "[
				Captures source and destination database
				references with default step configuration.
			]"
		require
			source_attached: a_source /= Void
			source_open: a_source.is_open
			destination_attached: a_destination /= Void
			destination_open: a_destination.is_open
		do
			source := a_source
			destination := a_destination
			pages_per_step := Default_pages_per_step
			sleep_ms_between_steps := 0
			max_busy_retries := Default_max_busy_retries
			busy_retry_delay_ms := Default_busy_retry_delay_ms
		ensure
			source_set: source = a_source
			destination_set: destination = a_destination
		end

	make_to_file (a_source: SIMPLE_SQL_DATABASE; a_destination_path: READABLE_STRING_GENERAL)
			-- Initialize backup from `a_source` database to file at `a_destination_path`
		note
			semantic_role: "[
				Opens a new file database as backup
				destination and marks it as owned.
			]"
		require
			source_attached: a_source /= Void
			source_open: a_source.is_open
			path_not_empty: not a_destination_path.is_empty
		do
			source := a_source
			create destination.make (a_destination_path)
			owns_destination := True
			pages_per_step := Default_pages_per_step
			sleep_ms_between_steps := 0
			max_busy_retries := Default_max_busy_retries
			busy_retry_delay_ms := Default_busy_retry_delay_ms
		ensure
			source_set: source = a_source
			destination_created: destination.is_open
			owns_destination_set: owns_destination
		end

	make_from_file (a_source_path: READABLE_STRING_GENERAL; a_destination: SIMPLE_SQL_DATABASE)
			-- Initialize backup from file at `a_source_path` to `a_destination` database
		note
			semantic_role: "[
				Opens a file database as backup source
				and marks it as owned.
			]"
		require
			path_not_empty: not a_source_path.is_empty
			source_exists: (create {RAW_FILE}.make_with_name (a_source_path)).exists
			destination_attached: a_destination /= Void
			destination_open: a_destination.is_open
		do
			create source.make_read_only (a_source_path)
			owns_source := True
			destination := a_destination
			pages_per_step := Default_pages_per_step
			sleep_ms_between_steps := 0
			max_busy_retries := Default_max_busy_retries
			busy_retry_delay_ms := Default_busy_retry_delay_ms
		ensure
			source_created: source.is_open
			destination_set: destination = a_destination
			owns_source_set: owns_source
		end

feature -- Access

	source: SIMPLE_SQL_DATABASE
			-- Source database to back up

	destination: SIMPLE_SQL_DATABASE
			-- Destination database for backup

	pages_remaining: INTEGER
			-- Pages remaining to be copied (valid during/after backup)

	total_pages: INTEGER
			-- Total number of pages in source database (valid during/after backup)

	last_error_code: INTEGER
			-- Last error code from backup operation

	last_error_message: STRING_32
			-- Human-readable error message
		note
			semantic_role: "[
				Translates the last error code to a
				human-readable message.
			]"
		do
			create Result.make_from_string (error_message_for_code (last_error_code))
		end

feature -- Status

	is_complete: BOOLEAN
			-- Was the last backup operation successful?

	had_error: BOOLEAN
			-- Did the last operation encounter an error?
		note
			semantic_role: "[
				Checks whether the last operation failed
				with a non-success code.
			]"
		do
			Result := last_error_code /= Backup_ok and last_error_code /= Backup_done
		end

	progress_percentage: REAL_64
			-- Current progress as percentage (0.0 to 100.0)
		note
			semantic_role: "[
				Computes backup progress as a percentage
				from page counts.
			]"
		do
			if total_pages > 0 then
				Result := ((total_pages - pages_remaining) / total_pages) * 100.0
			end
		ensure
			valid_range: Result >= 0.0 and Result <= 100.0
		end

feature -- Configuration

	pages_per_step: INTEGER
			-- Number of pages to copy per step in incremental backup

	sleep_ms_between_steps: INTEGER
			-- Milliseconds to sleep between incremental steps (for throttling)

	progress_callback: detachable PROCEDURE [INTEGER, INTEGER]
			-- Optional callback for progress updates: agent (remaining, total)

	max_busy_retries: INTEGER
			-- How many times one step is retried after SQLITE_BUSY or SQLITE_LOCKED before the
			-- backup gives up (SQLite documents both as retryable, not permanent).

	busy_retry_delay_ms: INTEGER
			-- Milliseconds to wait before each retry of a busy or locked step.

	busy_retry_callback: detachable PROCEDURE [INTEGER]
			-- Optional callback called before each retry with the retry number (1, 2, ...).

	busy_retries_done: INTEGER
			-- Retries made during the last backup.

	set_busy_retry (a_max_retries, a_delay_ms: INTEGER)
			-- Retry a busy or locked step up to `a_max_retries' times, waiting `a_delay_ms' each time.
		note
			semantic_role: "[
				Configures how long a backup keeps
				retrying a busy or locked source or
				destination.
			]"
			modifies: "max_busy_retries, busy_retry_delay_ms"
		require
			non_negative_retries: a_max_retries >= 0
			non_negative_delay: a_delay_ms >= 0
		do
			max_busy_retries := a_max_retries
			busy_retry_delay_ms := a_delay_ms
		ensure
			retries_set: max_busy_retries = a_max_retries
			delay_set: busy_retry_delay_ms = a_delay_ms
		end

	set_busy_retry_callback (a_callback: detachable PROCEDURE [INTEGER])
			-- Call `a_callback' (with the retry number) before each retry of a busy or locked step.
		note
			modifies: "busy_retry_callback"
		do
			busy_retry_callback := a_callback
		ensure
			callback_set: busy_retry_callback = a_callback
		end

	set_pages_per_step (a_count: INTEGER)
			-- Set number of pages to copy per incremental step
		note
			semantic_role: "[
				Configures how many pages to copy per
				incremental step.
			]"
			modifies: "pages_per_step"
		require
			positive_or_all: a_count > 0 or a_count = -1
		do
			pages_per_step := a_count
		ensure
			pages_set: pages_per_step = a_count
		end

	set_sleep_between_steps (a_ms: INTEGER)
			-- Set milliseconds to sleep between incremental steps
		note
			semantic_role: "[
				Configures throttle delay between
				incremental steps.
			]"
			modifies: "sleep_ms_between_steps"
		require
			non_negative: a_ms >= 0
		do
			sleep_ms_between_steps := a_ms
		ensure
			sleep_set: sleep_ms_between_steps = a_ms
		end

	set_progress_callback (a_callback: PROCEDURE [INTEGER, INTEGER])
			-- Set progress callback that receives (pages_remaining, total_pages)
		note
			semantic_role: "[
				Registers a callback agent for progress
				notifications.
			]"
			modifies: "progress_callback"
		do
			progress_callback := a_callback
		ensure
			callback_set: progress_callback = a_callback
		end

feature -- Operations

	execute
			-- Execute complete backup in one operation
		note
			semantic_role: "[
				Performs a complete one-shot backup of
				all pages.
			]"
		require
			source_open: source.is_open
			destination_open: destination.is_open
		do
			execute_with_pages (-1)
		end

	execute_incremental
			-- Execute backup incrementally, `pages_per_step` pages at a time
			-- Calls progress_callback after each step if set
		note
			semantic_role: "[
				Performs backup in steps with optional
				progress reporting and throttling.
			]"
		require
			source_open: source.is_open
			destination_open: destination.is_open
		do
			execute_with_pages (pages_per_step)
		end

	close
			-- Clean up resources
		note
			semantic_role: "[
				Releases owned database connections.
			]"
		do
			if owns_source and then source.is_open then
				source.close
			end
			if owns_destination and then destination.is_open then
				destination.close
			end
		end

feature {NONE} -- Implementation

	execute_with_pages (a_pages: INTEGER)
			-- Execute backup copying `a_pages` pages per step (-1 for all at once)
		note
			semantic_role: "[
				Core backup loop using SQLite Backup API
				with step-based page copying.
			]"
			modifies: "is_complete, last_error_code, pages_remaining, total_pages"
		local
			l_backup: POINTER
			l_result: INTEGER
			l_env: EXECUTION_ENVIRONMENT
		do
			is_complete := False
			last_error_code := Backup_ok
			busy_retries_done := 0

			-- Initialize backup
			l_backup := backup_init (
				destination.internal_db,
				Main_database,
				source.internal_db,
				Main_database
			)

			if l_backup = default_pointer then
				-- Failed to initialize - get error from destination
				last_error_code := -1
			else
				-- Update initial counts
				pages_remaining := backup_remaining (l_backup)
				total_pages := backup_pagecount (l_backup)

				-- Notify initial progress
				if attached progress_callback as al_l_callback then
					al_l_callback.call ([pages_remaining, total_pages])
				end

				-- Perform backup steps (each one retried while busy or locked)
				from
					l_result := retried_step (l_backup, a_pages)
					update_progress (l_backup)
				until
					l_result = Backup_done or (l_result /= Backup_ok and l_result /= Backup_done)
				loop
					-- Notify progress
					if attached progress_callback as al_l_callback then
						al_l_callback.call ([pages_remaining, total_pages])
					end

					-- Optional sleep for throttling
					if sleep_ms_between_steps > 0 then
						create l_env
						l_env.sleep (sleep_ms_between_steps * 1_000_000) -- Convert ms to nanoseconds
					end

					l_result := retried_step (l_backup, a_pages)
					update_progress (l_backup)
				end

				last_error_code := l_result
				is_complete := (l_result = Backup_done)

				-- Always finish the backup to release resources
				l_result := backup_finish (l_backup)
				if last_error_code = Backup_done then
					last_error_code := l_result
				end
			end
		end

	retried_step (a_backup: POINTER; a_pages: INTEGER): INTEGER
			-- `backup_step', repeated after SQLITE_BUSY or SQLITE_LOCKED up to `max_busy_retries' times.
		note
			semantic_role: "[
				Retries the retryable step results that
				used to end a backup as a failure.
			]"
			modifies: "busy_retries_done"
		require
			valid_backup: a_backup /= default_pointer
		local
			l_tries: INTEGER
			l_env: EXECUTION_ENVIRONMENT
		do
			from
				Result := backup_step (a_backup, a_pages)
			until
				not is_busy_or_locked (Result) or l_tries >= max_busy_retries
			loop
				l_tries := l_tries + 1
				busy_retries_done := busy_retries_done + 1
				if attached busy_retry_callback as al_callback then
					al_callback.call ([busy_retries_done])
				end
				if busy_retry_delay_ms > 0 then
					create l_env
					l_env.sleep (busy_retry_delay_ms.to_integer_64 * 1_000_000)
				end
				Result := backup_step (a_backup, a_pages)
			variant
				max_busy_retries - l_tries
			end
		end

	is_busy_or_locked (a_code: INTEGER): BOOLEAN
			-- Is `a_code' (possibly extended) SQLITE_BUSY or SQLITE_LOCKED?
		do
			Result := (a_code & 0xFF) = 5 or (a_code & 0xFF) = 6
		end

	update_progress (a_backup: POINTER)
			-- Update progress attributes from backup handle
		note
			semantic_role: "[
				Refreshes page count attributes from
				the backup handle.
			]"
			modifies: "pages_remaining, total_pages"
		require
			valid_backup: a_backup /= default_pointer
		do
			pages_remaining := backup_remaining (a_backup)
			total_pages := backup_pagecount (a_backup)
		end

	error_message_for_code (a_code: INTEGER): STRING_8
			-- Human-readable message for error code
		note
			semantic_role: "[
				Maps SQLite error codes to descriptive
				messages.
			]"
		do
			inspect a_code
			when 0 then
				Result := "Success"
			when 101 then
				Result := "Backup completed"
			when 5 then
				Result := "Database is busy"
			when 6 then
				Result := "Database is locked"
			when 7 then
				Result := "Out of memory"
			when 8 then
				Result := "Attempt to write readonly database"
			when -1 then
				Result := "Failed to initialize backup"
			else
				Result := "Unknown error: " + a_code.out
			end
		end

	owns_source: BOOLEAN
			-- Do we own (and should close) the source database?

	owns_destination: BOOLEAN
			-- Do we own (and should close) the destination database?

feature -- Constants

	Default_pages_per_step: INTEGER = 100
			-- Default number of pages to copy per incremental step

	Default_max_busy_retries: INTEGER = 200
			-- Default retries of a busy or locked step (with the default delay: about 5 seconds)

	Default_busy_retry_delay_ms: INTEGER = 25
			-- Default wait before each retry of a busy or locked step

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
