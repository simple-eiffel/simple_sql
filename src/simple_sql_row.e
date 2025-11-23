note
	description: "[
		Single row from query result with named column access.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_ROW

create
	make

feature {NONE} -- Initialization

	make (a_capacity: INTEGER)
			-- Create row with capacity
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
		do
			Result := columns.count
		ensure
			non_negative: Result >= 0
			consistent: Result = values.count
		end

feature -- Status report

	has_column (a_name: STRING_8): BOOLEAN
			-- Has column with name?
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
			end
		end

feature -- Access

	column_value (a_name: STRING_8): detachable ANY
			-- Value for column name
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
			end
		end

	item alias "[]" (i: INTEGER): detachable ANY
			-- Value at index
		require
			valid_index: i >= 1 and i <= count
		do
			Result := values.i_th (i)
		end

	column_name (i: INTEGER): STRING_8
			-- Column name at index
		require
			valid_index: i >= 1 and i <= count
		do
			Result := columns.i_th (i)
		ensure
			result_attached: Result /= Void
		end

feature -- Conversion

	string_value (a_name: STRING_8): STRING_32
			-- String value for column
		require
			has_column: has_column (a_name)
		do
			if attached {READABLE_STRING_GENERAL} column_value (a_name) as al_string then
				Result := al_string.to_string_32
			else
				create Result.make_empty
			end
		ensure
			result_attached: Result /= Void
		end

	integer_value (a_name: STRING_8): INTEGER
			-- Integer value for column
		require
			has_column: has_column (a_name)
		do
			if attached {INTEGER_64} column_value (a_name) as al_int then
				Result := al_int.to_integer_32
			end
		end

	integer_64_value (a_name: STRING_8): INTEGER_64
			-- Integer_64 value for column
		require
			has_column: has_column (a_name)
		do
			if attached {INTEGER_64} column_value (a_name) as al_int then
				Result := al_int
			end
		end

	real_value (a_name: STRING_8): REAL_64
			-- Real value for column
		require
			has_column: has_column (a_name)
		do
			if attached {REAL_64} column_value (a_name) as al_real then
				Result := al_real
			end
		end

	is_null (a_name: STRING_8): BOOLEAN
			-- Is column null?
		require
			has_column: has_column (a_name)
		do
			Result := column_value (a_name) = Void
		end

feature {SIMPLE_SQL_RESULT} -- Element change

	add_column (a_name: STRING_8; a_value: detachable ANY)
			-- Add column with value
		require
			name_not_empty: not a_name.is_empty
		do
			columns.extend (a_name)
			values.extend (a_value)
		ensure
			count_increased: count = old count + 1
		end

invariant
	columns_attached: columns /= Void
	values_attached: values /= Void
	same_count: columns.count = values.count

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_SQL - High-level SQLite API for Eiffel
	]"

end
