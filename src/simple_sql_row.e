note
	description: "[
		Represents a single database row with named column access, serving as
		the fundamental data carrier in simple_sql query results. Maps SQLite
		column names to their runtime values, providing type-safe extraction
		through typed accessor features (string_value, integer_value, real_value,
		blob_value) and nullable variants for columns that may contain NULL.

		Populated by SIMPLE_SQL_RESULT during query execution, each row maintains
		parallel lists of column names and values in insertion order. Clients
		access data by column name rather than positional index, insulating
		application code from SELECT clause ordering.

		Includes simple_encoding integration for UTF-8 validation of string
		columns, and MML model queries for formal contract verification.
	]"
	purpose: "Named-column data carrier for SQLite query result rows"
	collaborators: "SIMPLE_SQL_RESULT, SIMPLE_SQL_CURSOR, SIMPLE_SQL_RESULT_STREAM, SIMPLE_ENCODING_DETECTOR, MML_SEQUENCE"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_ROW

create
	make

feature {NONE} -- Initialization

	make (a_capacity: INTEGER)
			-- Create row with capacity
		note
			semantic_role: "[
				Establishes the parallel column-name/value
				lists that define row structure,
				pre-allocating for the expected number of
				columns in the query result.
			]"
		require
			positive_capacity: a_capacity > 0
		do
			create columns.make (a_capacity)
			create values.make (a_capacity)
		ensure
			columns_attached: columns /= Void
			values_attached: values /= Void
		end

feature -- Access

	columns: ARRAYED_LIST [STRING_8]
			-- Column names

	values: ARRAYED_LIST [detachable ANY]
			-- Column values

feature -- Measurement

	count: INTEGER
			-- Number of columns
		note
			semantic_role: "[
				Reports column count for iteration bounds
				and parallel-list consistency verification.
			]"
		do
			Result := columns.count
		ensure
			non_negative: Result >= 0
			consistent: Result = values.count
		end

feature -- Status report

	has_column (a_name: STRING_8): BOOLEAN
			-- Has column with name?
		note
			semantic_role: "[
				Column existence predicate used as
				precondition guard for all typed accessors.
			]"
		require
			name_not_empty: not a_name.is_empty
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > columns.count or Result
			loop
				if columns.i_th (i) ~ a_name then
					Result := True
				end
				i := i + 1
			variant
				columns.count - i + 1
			end
		end

feature -- Access

	column_value (a_name: STRING_8): detachable ANY
			-- Value for column name
		note
			semantic_role: "[
				Raw value retrieval by column name,
				foundation for all typed accessor features.
			]"
		require
			has_column: has_column (a_name)
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > columns.count or Result /= Void
			loop
				if columns.i_th (i) ~ a_name then
					Result := values.i_th (i)
				end
				i := i + 1
			variant
				columns.count - i + 1
			end
		end

	item alias "[]" (a_i: INTEGER): detachable ANY
			-- Value at index
		note
			semantic_role: "[
				Positional value access for iteration-based
				processing where column names are not needed.
			]"
		require
			valid_index: a_i >= 1 and a_i <= count
		do
			Result := values.i_th (a_i)
		end

	column_name (a_i: INTEGER): STRING_8
			-- Column name at index
		note
			semantic_role: "[
				Positional column name lookup, inverse of
				column_value for metadata-driven processing.
			]"
		require
			valid_index: a_i >= 1 and a_i <= count
		do
			Result := columns.i_th (a_i)
		ensure
			result_attached: Result /= Void
		end

feature -- Conversion

	string_value (a_name: STRING_8): STRING_32
			-- String value for column, with proper UTF-8 decoding.
			-- SQLite always stores text as UTF-8; raw bytes in STRING_8
			-- must be decoded to STRING_32 via simple_encoding.
		note
			semantic_role: "[
				Type-safe string extraction with UTF-8
				decoding, the most common accessor for
				text-heavy database schemas.
			]"
		require
			has_column: has_column (a_name)
		do
			if attached {STRING_8} column_value (a_name) as al_s8 then
				Result := utf8_decoder.utf_8_to_utf_32 (al_s8)
			elseif attached {READABLE_STRING_GENERAL} column_value (a_name) as al_string then
				Result := al_string.to_string_32
			else
				create Result.make_empty
			end
		ensure
			result_attached: Result /= Void
		end

	integer_value (a_name: STRING_8): INTEGER
			-- Integer value for column
		note
			semantic_role: "[
				Type-safe integer extraction with
				64-to-32-bit narrowing for standard
				integer columns.
			]"
		require
			has_column: has_column (a_name)
		do
			if attached {INTEGER_64} column_value (a_name) as al_int then
				Result := al_int.to_integer_32
			end
		end

	integer_64_value (a_name: STRING_8): INTEGER_64
			-- Integer_64 value for column
		note
			semantic_role: "[
				Full-precision integer extraction for
				columns exceeding 32-bit range.
			]"
		require
			has_column: has_column (a_name)
		do
			if attached {INTEGER_64} column_value (a_name) as al_int then
				Result := al_int
			end
		end

	real_value (a_name: STRING_8): REAL_64
			-- Real value for column
		note
			semantic_role: "[
				Type-safe floating-point extraction for
				numeric columns stored as REAL.
			]"
		require
			has_column: has_column (a_name)
		do
			if attached {REAL_64} column_value (a_name) as al_real then
				Result := al_real
			end
		end

	blob_value (a_name: STRING_8): detachable MANAGED_POINTER
			-- BLOB (binary data) value for column
			-- Returns MANAGED_POINTER containing binary data, or Void if NULL
		note
			semantic_role: "[
				Binary data extraction returning managed
				memory pointer for BLOB columns.
			]"
		require
			has_column: has_column (a_name)
		do
			if attached {MANAGED_POINTER} column_value (a_name) as al_blob then
				Result := al_blob
			end
		end

	is_null (a_name: STRING_8): BOOLEAN
			-- Is column null?
		note
			semantic_role: "[
				NULL detection predicate, essential for
				distinguishing database NULL from default
				zero/empty values.
			]"
		require
			has_column: has_column (a_name)
		do
			Result := column_value (a_name) = Void
		end

feature -- Nullable Accessors

	string_value_or_void (a_name: STRING_8): detachable STRING_8
			-- String value for column, or Void if null.
			-- Convenience method for nullable string columns.
		note
			semantic_role: "[
				Nullable string accessor preserving database
				NULL as Void, avoiding false empty-string
				substitution.
			]"
		require
			has_column: has_column (a_name)
		do
			if not is_null (a_name) then
				Result := string_value (a_name).to_string_8
			end
		end

	integer_value_or_void (a_name: STRING_8): detachable INTEGER_REF
			-- Integer value for column, or Void if null.
			-- Convenience method for nullable integer columns.
		note
			semantic_role: "[
				Nullable integer accessor preserving
				database NULL as Void for columns where
				zero is a valid value.
			]"
		require
			has_column: has_column (a_name)
		do
			if not is_null (a_name) then
				Result := integer_value (a_name)
			end
		end

	integer_64_value_or_void (a_name: STRING_8): detachable INTEGER_64_REF
			-- Integer_64 value for column, or Void if null.
			-- Convenience method for nullable integer columns.
		note
			semantic_role: "[
				Nullable 64-bit integer accessor preserving
				database NULL as Void.
			]"
		require
			has_column: has_column (a_name)
		do
			if not is_null (a_name) then
				Result := integer_64_value (a_name)
			end
		end

	real_value_or_void (a_name: STRING_8): detachable REAL_64_REF
			-- Real value for column, or Void if null.
			-- Convenience method for nullable real columns.
		note
			semantic_role: "[
				Nullable real accessor preserving database
				NULL as Void for columns where 0.0 is a
				valid value.
			]"
		require
			has_column: has_column (a_name)
		do
			if not is_null (a_name) then
				Result := real_value (a_name)
			end
		end

	string_value_or_default (a_name: STRING_8; a_default: STRING_8): STRING_8
			-- String value for column, or default if null.
		note
			semantic_role: "[
				Null-coalescing string accessor providing
				caller-specified fallback for NULL columns.
			]"
		require
			has_column: has_column (a_name)
		do
			if is_null (a_name) then
				Result := a_default
			else
				Result := string_value (a_name).to_string_8
			end
		end

	integer_value_or_default (a_name: STRING_8; a_default: INTEGER): INTEGER
			-- Integer value for column, or default if null.
		note
			semantic_role: "[
				Null-coalescing integer accessor providing
				caller-specified fallback for NULL columns.
			]"
		require
			has_column: has_column (a_name)
		do
			if is_null (a_name) then
				Result := a_default
			else
				Result := integer_value (a_name)
			end
		end

	integer_64_value_or_default (a_name: STRING_8; a_default: INTEGER_64): INTEGER_64
			-- Integer_64 value for column, or default if null.
		note
			semantic_role: "[
				Null-coalescing 64-bit integer accessor
				providing caller-specified fallback for
				NULL columns.
			]"
		require
			has_column: has_column (a_name)
		do
			if is_null (a_name) then
				Result := a_default
			else
				Result := integer_64_value (a_name)
			end
		end

	boolean_value (a_name: STRING_8): BOOLEAN
			-- Boolean value for column (treats 0 as False, non-zero as True).
			-- Commonly used for SQLite INTEGER columns storing boolean values.
		note
			semantic_role: "[
				SQLite boolean interpretation matching
				SQLite's lack of native boolean type.
			]"
		require
			has_column: has_column (a_name)
		do
			Result := integer_value (a_name) /= 0
		end

feature -- UTF-8 Validation (simple_encoding integration)

	is_string_valid_utf8 (a_name: STRING_8): BOOLEAN
			-- Is the string value at `a_name' valid UTF-8?
			-- Returns True for NULL or non-string values.
		note
			semantic_role: "[
				Per-column UTF-8 validation using
				simple_encoding for data integrity
				verification.
			]"
		require
			has_column: has_column (a_name)
		local
			l_detector: SIMPLE_ENCODING_DETECTOR
		do
			if is_null (a_name) then
				Result := True
			elseif attached {READABLE_STRING_GENERAL} column_value (a_name) as al_l_str then
				create l_detector.make
				Result := l_detector.is_valid_utf8 (al_l_str.to_string_8)
			else
				Result := True -- Non-string values are considered valid
			end
		end

	all_strings_valid_utf8: BOOLEAN
			-- Are all string columns valid UTF-8?
		note
			semantic_role: "[
				Whole-row UTF-8 validation sweep for batch
				integrity verification.
			]"
		local
			i: INTEGER
		do
			Result := True
			from
				i := 1
			until
				i > count or not Result
			loop
				if attached {READABLE_STRING_GENERAL} values.i_th (i) then
					Result := is_string_valid_utf8 (columns.i_th (i))
				end
				i := i + 1
			variant
				count - i + 1
			end
		end

	detected_encoding (a_name: STRING_8): STRING
			-- Detect encoding of string value at `a_name'.
			-- Returns "UTF-8", "ASCII", "LATIN1", etc.
		note
			semantic_role: "[
				Character encoding detection for
				encoding-aware text processing.
			]"
		require
			has_column: has_column (a_name)
			not_null: not is_null (a_name)
		local
			l_detector: SIMPLE_ENCODING_DETECTOR
		do
			if attached {READABLE_STRING_GENERAL} column_value (a_name) as al_l_str then
				create l_detector.make
				if attached l_detector.detect_encoding (al_l_str.to_string_8) as al_l_enc then
					Result := al_l_enc.to_string_8
				else
					Result := "UNKNOWN"
				end
			else
				Result := "BINARY"
			end
		ensure
			result_not_empty: not Result.is_empty
		end

feature -- Model Queries

	columns_model: MML_SEQUENCE [STRING_8]
			-- Mathematical model of column names in order.
		note
			semantic_role: "[
				MML specification of column name ordering
				for formal postcondition verification.
			]"
		do
			create Result
			across columns as ic loop
				Result := Result & ic
			end
		ensure
			count_matches: Result.count = columns.count
		end

	values_model: MML_SEQUENCE [detachable ANY]
			-- Mathematical model of column values in order.
		note
			semantic_role: "[
				MML specification of value ordering, paired
				with columns_model for parallel-list formal
				contracts.
			]"
		do
			create Result
			across values as ic loop
				Result := Result & ic
			end
		ensure
			count_matches: Result.count = values.count
		end

feature {SIMPLE_SQL_RESULT, SIMPLE_SQL_CURSOR, SIMPLE_SQL_RESULT_STREAM} -- Element change

	add_column (a_name: STRING_8; a_value: detachable ANY)
			-- Add column with value
		note
			semantic_role: "[
				Appends a name-value pair during row
				construction by query result collectors.
			]"
			modifies: "columns, values"
		require
			name_not_empty: not a_name.is_empty
		do
			columns.extend (a_name)
			values.extend (a_value)
		ensure
			count_increased: count = old count + 1
			column_added: columns_model.last = a_name
			value_added: values_model.last = a_value
			columns_prefix_unchanged: old columns_model <= columns_model
			values_prefix_unchanged: old values_model <= values_model
		end

feature {NONE} -- UTF-8 Decoding

	utf8_decoder: SIMPLE_ENCODING
			-- Shared UTF-8 decoder for string value extraction.
		once
			create Result.make
		end

invariant
	columns_attached: columns /= Void
	values_attached: values /= Void
	same_count: columns.count = values.count

	-- Model consistency
	model_columns_count: columns_model.count = count
	model_values_count: values_model.count = count

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
