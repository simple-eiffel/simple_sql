note
	description: "DMS Folder - hierarchical folder structure with path tracking"
	date: "$Date$"
	revision: "$Revision$"

class
	DMS_FOLDER

create
	make,
	make_new,
	make_root

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_owner_id: INTEGER_64; a_parent_id: detachable INTEGER_64_REF;
			a_name, a_path: READABLE_STRING_8;
			a_created_at, a_updated_at: READABLE_STRING_8;
			a_deleted_at: detachable READABLE_STRING_8)
			-- Initialize from database row.
		require
			name_not_empty: not a_name.is_empty
			path_not_empty: not a_path.is_empty
		do
			id := a_id
			owner_id := a_owner_id
			parent_id := a_parent_id
			name := a_name.to_string_8
			path := a_path.to_string_8
			created_at := a_created_at.to_string_8
			updated_at := a_updated_at.to_string_8
			deleted_at := if attached a_deleted_at as d then d.to_string_8 else Void end
		ensure
			id_set: id = a_id
			name_set: name.same_string (a_name)
		end

	make_new (a_owner_id: INTEGER_64; a_parent_id: INTEGER_64; a_name: READABLE_STRING_8; a_parent_path: READABLE_STRING_8)
			-- Create a new folder under a parent.
		require
			name_not_empty: not a_name.is_empty
			valid_owner: a_owner_id > 0
			valid_parent: a_parent_id > 0
		local
			l_parent: INTEGER_64_REF
		do
			id := 0
			owner_id := a_owner_id
			create l_parent
			l_parent.set_item (a_parent_id)
			parent_id := l_parent
			name := a_name.to_string_8
			path := a_parent_path.to_string_8 + "/" + a_name.to_string_8
			created_at := ""
			updated_at := ""
		ensure
			is_new: id = 0
			has_parent: parent_id /= Void
		end

	make_root (a_owner_id: INTEGER_64)
			-- Create a root folder for a user.
		require
			valid_owner: a_owner_id > 0
		do
			id := 0
			owner_id := a_owner_id
			parent_id := Void
			name := "Root"
			path := "/"
			created_at := ""
			updated_at := ""
		ensure
			is_new: id = 0
			is_root: is_root
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier.

	owner_id: INTEGER_64
			-- Owner user ID.

	parent_id: detachable INTEGER_64_REF
			-- Parent folder ID (Void for root).

	name: STRING_8
			-- Folder name.

	path: STRING_8
			-- Full path from root (e.g., "/Documents/Work/Projects").

	created_at: STRING_8
			-- Creation timestamp.

	updated_at: STRING_8
			-- Last update timestamp.

	deleted_at: detachable STRING_8
			-- Soft delete timestamp.

feature -- Status

	is_new: BOOLEAN
			-- Not yet saved?
		do
			Result := id = 0
		end

	is_root: BOOLEAN
			-- Is this a root folder?
		do
			Result := parent_id = Void
		end

	is_deleted: BOOLEAN
			-- Is soft-deleted?
		do
			Result := deleted_at /= Void
		end

	is_active: BOOLEAN
			-- Is active (not deleted)?
		do
			Result := deleted_at = Void
		end

	depth: INTEGER
			-- Depth in hierarchy (root = 0).
		local
			l_count, i: INTEGER
		do
			from
				i := 1
			until
				i > path.count
			loop
				if path.item (i) = '/' then
					l_count := l_count + 1
				end
				i := i + 1
			end
			Result := l_count - 1
			if Result < 0 then
				Result := 0
			end
		end

feature -- Modification

	set_id (a_id: INTEGER_64)
			-- Set ID after insert.
		require
			was_new: id = 0
		do
			id := a_id
		end

	set_name (a_name: READABLE_STRING_8)
			-- Rename folder.
		require
			not_empty: not a_name.is_empty
		do
			name := a_name.to_string_8
		end

	set_path (a_path: READABLE_STRING_8)
			-- Update path.
		require
			not_empty: not a_path.is_empty
		do
			path := a_path.to_string_8
		end

	set_parent_id (a_parent_id: INTEGER_64)
			-- Move to new parent.
		require
			valid_parent: a_parent_id > 0
		do
			if parent_id = Void then
				create parent_id
			end
			if attached parent_id as p then
				p.set_item (a_parent_id)
			end
		end

	set_created_at (a_timestamp: READABLE_STRING_8)
		do
			created_at := a_timestamp.to_string_8
		end

	set_updated_at (a_timestamp: READABLE_STRING_8)
		do
			updated_at := a_timestamp.to_string_8
		end

	set_deleted_at (a_timestamp: detachable READABLE_STRING_8)
		do
			deleted_at := if attached a_timestamp as t then t.to_string_8 else Void end
		end

	soft_delete (a_timestamp: READABLE_STRING_8)
		require
			not_deleted: not is_deleted
		do
			deleted_at := a_timestamp.to_string_8
		ensure
			is_deleted: is_deleted
		end

	restore
		require
			was_deleted: is_deleted
		do
			deleted_at := Void
		ensure
			not_deleted: not is_deleted
		end

invariant
	name_not_empty: not name.is_empty
	path_not_empty: not path.is_empty
	root_has_no_parent: is_root implies (parent_id = Void)

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
