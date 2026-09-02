note
	description: "[
		Runner that applies and reverts schema migrations in version order using
		PRAGMA user_version for tracking.
		Maintains a sorted registry of SIMPLE_SQL_MIGRATION objects and executes
		them within transaction boundaries with rollback on failure.
		Orchestrates simple_sql schema evolution for reproducible upgrades and downgrades.
	]"
	purpose: "Execute ordered schema migrations with transactional safety and version tracking"
	collaborators: "SIMPLE_SQL_DATABASE, SIMPLE_SQL_SCHEMA, SIMPLE_SQL_MIGRATION"
	design_pattern: "Command"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_MIGRATION_RUNNER

create
	make

feature {NONE} -- Initialization

	make (a_database: SIMPLE_SQL_DATABASE)
			-- Create migration runner for database
		note
			semantic_role: "[
				Binds the runner to a database and
				initializes the migration registry with
				schema inspector for version tracking.
			]"
		require
			database_open: a_database.is_open
		do
			database := a_database
			create migrations.make (10)
			create schema.make (a_database)
			create last_error.make_empty
		ensure
			database_set: database = a_database
		end

feature -- Access

	database: SIMPLE_SQL_DATABASE
			-- Target database

	schema: SIMPLE_SQL_SCHEMA
			-- Schema inspector

	migrations: ARRAYED_LIST [SIMPLE_SQL_MIGRATION]
			-- Registered migrations (sorted by version)

	current_version: INTEGER
			-- Current database schema version
		note
			semantic_role: "[
				Queries the database PRAGMA user_version
				to determine current schema state.
			]"
		do
			Result := schema.user_version
		end

	latest_version: INTEGER
			-- Highest migration version registered
		note
			semantic_role: "[
				Reports the highest registered migration
				version, defining the target for full
				upgrade.
			]"
		do
			if not migrations.is_empty then
				Result := migrations.last.version
			end
		end

	pending_migrations: ARRAYED_LIST [SIMPLE_SQL_MIGRATION]
			-- Migrations that haven't been applied yet
		note
			semantic_role: "[
				Computes the ordered list of unapplied
				migrations by filtering against
				current_version.
			]"
		local
			l_current: INTEGER
		do
			create Result.make (5)
			l_current := current_version
			across migrations as ic loop
				if ic.version > l_current then
					Result.extend (ic)
				end
			end
		end

	last_error: STRING_8
			-- Last error message (empty if no error)

feature -- Status

	has_error: BOOLEAN
			-- Did the last operation fail?
		note
			semantic_role: "[
				Error state predicate for checking
				whether the last migration operation
				failed.
			]"
		do
			Result := not last_error.is_empty
		end

	has_pending: BOOLEAN
			-- Are there pending migrations?
		note
			semantic_role: "[
				Pending migration predicate for deciding
				whether a migrate call is needed.
			]"
		do
			Result := current_version < latest_version
		end

	is_current: BOOLEAN
			-- Is database at latest version?
		note
			semantic_role: "[
				Schema currency check, true when
				database is at the latest registered
				migration version.
			]"
		do
			Result := current_version = latest_version
		end

feature -- Registration

	add (a_migration: SIMPLE_SQL_MIGRATION)
			-- Register a migration
		note
			semantic_role: "[
				Registers a migration in version-sorted
				order, building the ordered registry
				that migrate/rollback traverses.
			]"
			modifies: "migrations"
		require
			migration_attached: attached a_migration
			unique_version: not has_version (a_migration.version)
		local
			i: INTEGER
			l_inserted: BOOLEAN
		do
			-- Insert in sorted order by version
			from i := 1 until i > migrations.count or l_inserted loop
				if a_migration.version < migrations [i].version then
					migrations.go_i_th (i)
					migrations.put_left (a_migration)
					l_inserted := True
				end
				i := i + 1
			end
			if not l_inserted then
				migrations.extend (a_migration)
			end
		ensure
			migration_added: migrations.has (a_migration)
			count_increased: migrations.count = old migrations.count + 1
			model_has_migration: migrations_model.has (a_migration)
			model_count: migrations_model.count = old migrations_model.count + 1
		end

feature -- Model Queries

	migrations_model: MML_SEQUENCE [SIMPLE_SQL_MIGRATION]
			-- Mathematical model of registered migrations in order.
		note
			semantic_role: "[
				MML specification of migration ordering
				for formal contract verification.
			]"
		do
			create Result
			across migrations as ic loop
				Result := Result & ic
			end
		ensure
			count_matches: Result.count = migrations.count
		end

feature -- Status queries

	has_version (a_version: INTEGER): BOOLEAN
			-- Is a migration with this version already registered?
		note
			semantic_role: "[
				Version uniqueness check used as
				precondition for add to prevent
				duplicate registrations.
			]"
		do
			across migrations as ic loop
				if ic.version = a_version then
					Result := True
				end
			end
		end

feature -- Migration Operations

	migrate: BOOLEAN
			-- Run all pending migrations
			-- Returns True if successful
		note
			semantic_role: "[
				Applies all pending migrations in
				version order, the primary upgrade
				entry point.
			]"
		do
			Result := migrate_to (latest_version)
		end

	migrate_to (a_target_version: INTEGER): BOOLEAN
			-- Migrate to specific version (up or down)
			-- Returns True if successful
		note
			semantic_role: "[
				Bidirectional version targeting that
				applies or reverts migrations to reach
				a specific schema version.
			]"
		require
			valid_version: a_target_version >= 0
		local
			l_current: INTEGER
		do
			last_error.wipe_out
			l_current := current_version

			if a_target_version > l_current then
				Result := migrate_up_to (a_target_version)
			elseif a_target_version < l_current then
				Result := migrate_down_to (a_target_version)
			else
				-- Already at target version
				Result := True
			end
		end

	migrate_one: BOOLEAN
			-- Run the next pending migration only
			-- Returns True if successful
		note
			semantic_role: "[
				Single-step migration for controlled
				incremental upgrades.
			]"
		local
			l_pending: like pending_migrations
		do
			last_error.wipe_out
			l_pending := pending_migrations
			if not l_pending.is_empty then
				Result := apply_migration (l_pending.first)
			else
				Result := True -- Nothing to do
			end
		end

	rollback: BOOLEAN
			-- Rollback the last migration
			-- Returns True if successful
		note
			semantic_role: "[
				Reverts the most recent migration, the
				primary undo entry point.
			]"
		local
			l_current: INTEGER
			l_migration: detachable SIMPLE_SQL_MIGRATION
		do
			last_error.wipe_out
			l_current := current_version
			if l_current > 0 then
				-- Find migration at current version
				across migrations as ic loop
					if ic.version = l_current then
						l_migration := ic
					end
				end
				if attached l_migration as al_l_m then
					Result := revert_migration (al_l_m)
				else
					last_error := "No l_migration found for version " + l_current.out
					Result := False
				end
			else
				Result := True -- Nothing to rollback
			end
		end

	rollback_all: BOOLEAN
			-- Rollback all migrations
			-- Returns True if successful
		note
			semantic_role: "[
				Full schema revert to version 0, used
				for clean-slate testing and development.
			]"
		do
			Result := migrate_to (0)
		end

	reset: BOOLEAN
			-- Rollback all then migrate all (fresh start)
			-- Returns True if successful
		note
			semantic_role: "[
				Rollback-then-migrate sequence for fresh
				schema rebuild during development.
			]"
		do
			if rollback_all then
				Result := migrate
			end
		end

feature {NONE} -- Implementation

	migrate_up_to (a_target: INTEGER): BOOLEAN
			-- Apply migrations up to target version
		note
			semantic_role: "[
				Forward migration loop applying each
				pending migration up to the target
				version.
			]"
		local
			l_current: INTEGER
		do
			Result := True
			l_current := current_version
			across migrations as ic loop
				if Result and then ic.version > l_current and then ic.version <= a_target then
					Result := apply_migration (ic)
				end
			end
		end

	migrate_down_to (a_target: INTEGER): BOOLEAN
			-- Revert migrations down to target version
		note
			semantic_role: "[
				Reverse migration loop reverting each
				applied migration down to the target
				version.
			]"
		local
			l_current, i: INTEGER
		do
			Result := True
			l_current := current_version

			-- Go backwards through migrations
			from i := migrations.count until i < 1 or not Result loop
				if migrations [i].version <= l_current and then migrations [i].version > a_target then
					Result := revert_migration (migrations [i])
				end
				i := i - 1
			end
		end

	apply_migration (a_migration: SIMPLE_SQL_MIGRATION): BOOLEAN
			-- Apply a single migration
		note
			semantic_role: "[
				Transaction-wrapped single migration
				application with error capture and
				version stamping.
			]"
		require
			migration_attached: attached a_migration
		do
			database.begin_transaction
			a_migration.up (database)
			if database.has_error then
				database.rollback_transaction
				if attached database.last_error_message as al_l_msg then
					last_error := "Migration " + a_migration.version.out + " failed: " + al_l_msg.to_string_8
				else
					last_error := "Migration " + a_migration.version.out + " failed"
				end
				Result := False
			else
				schema.set_user_version (a_migration.version)
				database.commit_transaction
				Result := True
			end
		end

	revert_migration (a_migration: SIMPLE_SQL_MIGRATION): BOOLEAN
			-- Revert a single migration
		note
			semantic_role: "[
				Transaction-wrapped single migration
				reversal with previous version
				restoration.
			]"
		require
			migration_attached: attached a_migration
		local
			l_previous_version: INTEGER
		do
			-- Find previous version
			l_previous_version := 0
			across migrations as ic loop
				if ic.version < a_migration.version then
					l_previous_version := ic.version
				end
			end

			database.begin_transaction
			a_migration.down (database)
			if database.has_error then
				database.rollback_transaction
				if attached database.last_error_message as al_l_msg then
					last_error := "Rollback of migration " + a_migration.version.out + " failed: " + al_l_msg.to_string_8
				else
					last_error := "Rollback of migration " + a_migration.version.out + " failed"
				end
				Result := False
			else
				schema.set_user_version (l_previous_version)
				database.commit_transaction
				Result := True
			end
		end

invariant
	database_attached: attached database
	schema_attached: attached schema
	migrations_sorted: across 1 |..| (migrations.count - 1) as i all
		migrations [i.item].version < migrations [i.item + 1].version
	end

	-- Model consistency
	model_migrations_count: migrations_model.count = migrations.count

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
