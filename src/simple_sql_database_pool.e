note
	description: "Database connection pool using SIMPLE_CACHED_VALUE for connection reuse"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_DATABASE_POOL

create
	make

feature {NONE} -- Initialization

	make
			-- Create database pool.
		do
			default_database_path := ":memory:"
		ensure
			default_set: default_database_path ~ ":memory:"
		end

feature -- Access

	database_for_path (a_path: STRING): SIMPLE_SQL_DATABASE
			-- Get or create database connection for `a_path'.
			-- Connections are cached and reused for the same path.
		require
			path_not_empty: not a_path.is_empty
		do
			Result := internal_cache.item (a_path)
		ensure
			result_exists: Result /= Void
			result_open: Result.is_open
			is_cached: is_cached (a_path)
		end

	memory_database: SIMPLE_SQL_DATABASE
			-- Get cached in-memory database.
		do
			Result := database_for_path (":memory:")
		ensure
			result_exists: Result /= Void
			result_open: Result.is_open
		end

	is_cached (a_path: STRING): BOOLEAN
			-- Is there a cached connection for `a_path'?
		require
			path_not_empty: not a_path.is_empty
		do
			Result := internal_cache.is_cached (a_path)
		end

	cached_count: INTEGER
			-- Number of cached database connections.
		do
			Result := internal_cache.cached_count
		end

feature -- Configuration

	default_database_path: STRING
			-- Default database path for new connections.

	set_default_database_path (a_path: STRING)
			-- Set default database path.
		require
			path_not_empty: not a_path.is_empty
		do
			default_database_path := a_path
		ensure
			set: default_database_path ~ a_path
		end

feature -- Cache Management

	invalidate (a_path: STRING)
			-- Close and remove cached connection for `a_path'.
		require
			path_not_empty: not a_path.is_empty
		do
			if is_cached (a_path) then
				-- Close the database before invalidating
				if attached {SIMPLE_SQL_DATABASE} internal_cache.item (a_path) as l_db then
					l_db.close
				end
			end
			internal_cache.invalidate (a_path)
		ensure
			not_cached: not is_cached (a_path)
		end

	invalidate_all
			-- Close and remove all cached connections.
		do
			-- Note: Ideally we'd close all before invalidating,
			-- but the cache doesn't provide iteration.
			-- Rely on GC for cleanup.
			internal_cache.invalidate_all
		ensure
			empty: cached_count = 0
		end

feature {NONE} -- Implementation

	internal_cache: SIMPLE_CACHED_VALUE [SIMPLE_SQL_DATABASE, STRING]
			-- Cache of database connections by path (lazy initialization).
		once ("OBJECT")
			create Result.make (agent create_database_for_path)
		end

	create_database_for_path (a_path: STRING): SIMPLE_SQL_DATABASE
			-- Create new database connection for `a_path'.
		do
			if a_path ~ ":memory:" then
				create Result.make_memory
			else
				create Result.make (a_path)
			end
		ensure
			result_exists: Result /= Void
			result_open: Result.is_open
		end

invariant
	default_path_not_empty: not default_database_path.is_empty
	count_non_negative: cached_count >= 0

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
