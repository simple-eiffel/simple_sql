note
	description: "DMS Schema Version - tracks database schema migrations"
	date: "$Date$"
	revision: "$Revision$"

class
	DMS_SCHEMA_VERSION

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_version: INTEGER;
			a_name, a_description: READABLE_STRING_8;
			a_applied_at: READABLE_STRING_8;
			a_checksum: detachable READABLE_STRING_8;
			a_execution_time_ms: INTEGER)
			-- Initialize from database row.
		require
			version_positive: a_version > 0
			name_not_empty: not a_name.is_empty
		do
			id := a_id
			version := a_version
			name := a_name.to_string_8
			description := a_description.to_string_8
			applied_at := a_applied_at.to_string_8
			checksum := if attached a_checksum as c then c.to_string_8 else Void end
			execution_time_ms := a_execution_time_ms
		end

	make_new (a_version: INTEGER; a_name, a_description: READABLE_STRING_8)
			-- Create a new migration record.
		require
			version_positive: a_version > 0
			name_not_empty: not a_name.is_empty
		do
			id := 0
			version := a_version
			name := a_name.to_string_8
			description := a_description.to_string_8
			applied_at := ""
			execution_time_ms := 0
		ensure
			is_new: id = 0
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier.

	version: INTEGER
			-- Migration version number.

	name: STRING_8
			-- Migration name (e.g., "001_create_users", "002_add_documents").

	description: STRING_8
			-- Description of what this migration does.

	applied_at: STRING_8
			-- When the migration was applied.

	checksum: detachable STRING_8
			-- Checksum of migration script (to detect modifications).

	execution_time_ms: INTEGER
			-- How long the migration took to execute.

feature -- Status

	is_new: BOOLEAN
		do
			Result := id = 0
		end

feature -- Modification

	set_id (a_id: INTEGER_64)
		require
			was_new: id = 0
		do
			id := a_id
		end

	set_applied_at (a_timestamp: READABLE_STRING_8)
		do
			applied_at := a_timestamp.to_string_8
		end

	set_checksum (a_checksum: READABLE_STRING_8)
		do
			checksum := a_checksum.to_string_8
		end

	set_execution_time_ms (a_time: INTEGER)
		do
			execution_time_ms := a_time
		end

invariant
	version_positive: version >= 1
	name_not_empty: not name.is_empty

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
