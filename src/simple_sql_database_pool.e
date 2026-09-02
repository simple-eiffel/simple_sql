note
	description: "[
		A database connection pool that caches and reuses SIMPLE_SQL_DATABASE
		connections keyed by file path.
		Creates connections lazily on first request via SIMPLE_CACHED_VALUE and
		returns cached connections on subsequent requests for the same path.
		Eliminates repeated open/close overhead for multi-database simple_sql applications.
	]"
	purpose: "Cache and reuse database connections by file path to avoid open/close overhead"
	collaborators: "SIMPLE_SQL_DATABASE, SIMPLE_CACHED_VALUE"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_DATABASE_POOL

create
	make

feature {NONE} -- Initialization

	make
			-- Create database pool.
		note
			semantic_role: "[
				Initializes pool with default in-memory
				path, deferring actual connection
				creation to first access.
			]"
		do
			default_database_path := ":memory:"
		ensure
			default_set: default_database_path ~ ":memory:"
		end

feature -- Access

	database_for_path (a_path: STRING): SIMPLE_SQL_DATABASE
			-- Get or create database connection for `a_path'.
			-- Connections are cached and reused for the same path.
		note
			semantic_role: "[
				Primary access point returning cached
				or newly-created database connection
				for a given path.
			]"
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
		note
			semantic_role: "[
				Convenience accessor for the shared
				in-memory database connection.
			]"
		do
			Result := database_for_path (":memory:")
		ensure
			result_exists: Result /= Void
			result_open: Result.is_open
		end

	is_cached (a_path: STRING): BOOLEAN
			-- Is there a cached connection for `a_path'?
		note
			semantic_role: "[
				Cache hit predicate for checking whether
				a connection already exists for a path.
			]"
		require
			path_not_empty: not a_path.is_empty
		do
			Result := internal_cache.is_cached (a_path)
		end

	cached_count: INTEGER
			-- Number of cached database connections.
		note
			semantic_role: "[
				Reports pool size for monitoring and
				capacity management.
			]"
		do
			Result := internal_cache.cached_count
		end

feature -- Configuration

	default_database_path: STRING
			-- Default database path for new connections.

	set_default_database_path (a_path: STRING)
			-- Set default database path.
		note
			semantic_role: "[
				Configures the default path used when
				no explicit path is provided.
			]"
			modifies: "default_database_path"
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
		note
			semantic_role: "[
				Closes a specific connection and removes
				it from cache, freeing database
				resources.
			]"
			modifies: "internal_cache"
		require
			path_not_empty: not a_path.is_empty
		do
			if is_cached (a_path) then
				-- Close the database before invalidating
				if attached {SIMPLE_SQL_DATABASE} internal_cache.item (a_path) as al_l_db then
					al_l_db.close
				end
			end
			internal_cache.invalidate (a_path)
		ensure
			not_cached: not is_cached (a_path)
		end

	invalidate_all
			-- Close and remove all cached connections.
		note
			semantic_role: "[
				Clears the entire pool, used during
				shutdown or connection reset.
			]"
			modifies: "internal_cache"
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
		note
			semantic_role: "[
				Factory agent creating new database
				connections when cache misses.
			]"
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
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
