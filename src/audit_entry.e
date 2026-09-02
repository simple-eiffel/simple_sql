note
	description: "[
		An immutable audit trail entry representing a single database change event.
		Captures operation type, timestamp, and before/after JSON values for INSERT,
		UPDATE, and DELETE operations with chronological ordering support.
		Provides contract-driven change tracking for the simple_sql audit subsystem.
	]"
	purpose: "Represent a single immutable audit record for database change tracking"
	collaborators: "SIMPLE_SQL_AUDIT"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	AUDIT_ENTRY

inherit
	ANY
		redefine
			is_equal
		end

create
	make

feature {NONE} -- Initialization

	make (a_audit_id: INTEGER_64; a_record_id: INTEGER_64; a_table_name: STRING_8;
			a_operation: STRING_8; a_timestamp: STRING_8;
			a_old_values: detachable STRING_32; a_new_values: detachable STRING_32)
			-- Create audit entry with all fields.
		note
			semantic_role: "[
				Constructs an immutable audit record
				with validated operation type and
				normalized case for change tracking.
			]"
		require
			valid_operation: is_valid_operation_string (a_operation)
			table_not_empty: not a_table_name.is_empty
			timestamp_not_empty: not a_timestamp.is_empty
		do
			audit_id := a_audit_id
			record_id := a_record_id
			table_name := a_table_name
			operation := a_operation.as_upper
			timestamp := a_timestamp
			old_values := a_old_values
			new_values := a_new_values
		ensure
			audit_id_set: audit_id = a_audit_id
			record_id_set: record_id = a_record_id
			table_name_set: table_name = a_table_name
			operation_set: operation.is_case_insensitive_equal (a_operation)
			timestamp_set: timestamp = a_timestamp
			old_values_set: old_values = a_old_values
			new_values_set: new_values = a_new_values
		end

feature -- Access

	audit_id: INTEGER_64
			-- Unique identifier for this audit entry.

	record_id: INTEGER_64
			-- The ID of the record being tracked.

	table_name: STRING_8
			-- The table this audit entry belongs to.

	operation: STRING_8
			-- Operation type: INSERT, UPDATE, or DELETE.

	timestamp: STRING_8
			-- When the change occurred (ISO 8601 format).

	old_values: detachable STRING_32
			-- JSON representation of values before change (NULL for INSERT).

	new_values: detachable STRING_32
			-- JSON representation of values after change (NULL for DELETE).

feature -- Status

	is_insert: BOOLEAN
			-- Is this an INSERT operation?
		note
			semantic_role: "[
				Operation type predicate for INSERT
				classification within audit trail.
			]"
		do
			Result := operation.is_case_insensitive_equal ("INSERT")
		ensure
			definition: Result = operation.is_case_insensitive_equal ("INSERT")
		end

	is_update: BOOLEAN
			-- Is this an UPDATE operation?
		note
			semantic_role: "[
				Operation type predicate for UPDATE
				classification within audit trail.
			]"
		do
			Result := operation.is_case_insensitive_equal ("UPDATE")
		ensure
			definition: Result = operation.is_case_insensitive_equal ("UPDATE")
		end

	is_delete: BOOLEAN
			-- Is this a DELETE operation?
		note
			semantic_role: "[
				Operation type predicate for DELETE
				classification within audit trail.
			]"
		do
			Result := operation.is_case_insensitive_equal ("DELETE")
		ensure
			definition: Result = operation.is_case_insensitive_equal ("DELETE")
		end

	is_valid_operation: BOOLEAN
			-- Is operation one of INSERT, UPDATE, DELETE?
		note
			semantic_role: "[
				Invariant-supporting predicate ensuring
				operation is within the valid enumeration
				of INSERT, UPDATE, DELETE.
			]"
		do
			Result := is_insert or is_update or is_delete
		ensure
			definition: Result = (is_insert or is_update or is_delete)
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Are entries equal based on audit_id?
		note
			semantic_role: "[
				Identity equality based on unique
				audit_id for collection membership
				and comparison tests.
			]"
		do
			Result := audit_id = a_other.audit_id
		end

	is_before (a_other: AUDIT_ENTRY): BOOLEAN
			-- Does this entry come chronologically before `other'?
			-- Based on timestamp comparison (lexicographic for ISO 8601).
		note
			semantic_role: "[
				Chronological ordering using ISO 8601
				timestamps with audit_id as tiebreaker
				for deterministic sort order.
			]"
		do
			Result := timestamp < a_other.timestamp or
				(timestamp.same_string (a_other.timestamp) and audit_id < a_other.audit_id)
		ensure
			definition: Result = (timestamp < a_other.timestamp or
				(timestamp.same_string (a_other.timestamp) and audit_id < a_other.audit_id))
		end

	same_record (a_other: AUDIT_ENTRY): BOOLEAN
			-- Do both entries refer to the same record?
		note
			semantic_role: "[
				Record identity check combining table
				name and record ID for cross-entry
				correlation.
			]"
		do
			Result := record_id = a_other.record_id and table_name.same_string (a_other.table_name)
		ensure
			definition: Result = (record_id = a_other.record_id and table_name.same_string (a_other.table_name))
		end

feature {NONE} -- Implementation

	is_valid_operation_string (a_op: STRING_8): BOOLEAN
			-- Is `op' a valid operation string?
		note
			semantic_role: "[
				Precondition helper validating operation
				strings before storage in the audit
				record.
			]"
		do
			Result := a_op.is_case_insensitive_equal ("INSERT") or
				a_op.is_case_insensitive_equal ("UPDATE") or
				a_op.is_case_insensitive_equal ("DELETE")
		end

invariant
	valid_operation: is_valid_operation
	table_not_empty: not table_name.is_empty
	timestamp_not_empty: not timestamp.is_empty
	insert_has_new_values: is_insert implies new_values /= Void
	delete_has_old_values: is_delete implies old_values /= Void
	update_has_both: is_update implies (old_values /= Void and new_values /= Void)

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
