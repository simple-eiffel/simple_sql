note
	description: "[
		Vector representation for embedding storage and similarity calculations.

		Wraps an array of REAL_64 values with serialization to/from BLOB format
		for SQLite storage. Provides mathematical operations for ML/AI use cases.

		Usage:
			-- Create from array
			create vec.make_from_array (<<0.1, 0.2, 0.3, 0.4>>)

			-- Create zero vector
			create vec.make_zero (384)  -- 384-dimensional zero vector

			-- Access elements
			val := vec.item (1)  -- 1-based indexing
			vec.put (0.5, 1)     -- Modify element

			-- Convert to/from BLOB
			blob := vec.to_blob
			create vec2.make_from_blob (blob)

			-- Mathematical operations
			magnitude := vec.magnitude
			normalized := vec.normalized
			dot := vec.dot_product (other_vec)
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_VECTOR

inherit
	ANY
		redefine
			is_equal,
			out
		end

create
	make_from_array,
	make_from_blob,
	make_zero

feature {NONE} -- Initialization

	make_from_array (a_values: ARRAY [REAL_64])
			-- Create vector from array of values
			-- Note: Input array bounds are remapped to 1-based indexing
		require
			values_not_empty: not a_values.is_empty
			no_nan_input: across a_values.lower |..| a_values.upper as idx all not a_values [idx].is_nan end
			no_infinity_input: across a_values.lower |..| a_values.upper as idx all not a_values [idx].is_positive_infinity and not a_values [idx].is_negative_infinity end
		local
			i: INTEGER
		do
			create values.make_filled (0.0, 1, a_values.count)
			from i := 1 until i > a_values.count loop
				values [i] := a_values [a_values.lower + i - 1]
				i := i + 1
			variant
				a_values.count - i + 1
			end
		ensure
			dimension_set: dimension = a_values.count
			values_copied: across 1 |..| dimension as ic all item (ic) = a_values [a_values.lower + ic - 1] end
		end

	make_from_blob (a_blob: MANAGED_POINTER)
			-- Create vector from BLOB data (IEEE 754 double-precision, little-endian)
		require
			blob_not_void: a_blob /= Void
			blob_valid_size: a_blob.count \\ Real_64_bytes = 0
			blob_not_empty: a_blob.count > 0
		local
			l_count, i: INTEGER
		do
			l_count := a_blob.count // Real_64_bytes
			create values.make_filled (0.0, 1, l_count)
			from i := 1 until i > l_count loop
				values [i] := a_blob.read_real_64_le ((i - 1) * Real_64_bytes)
				i := i + 1
			variant
				l_count - i + 1
			end
		ensure
			dimension_set: dimension = a_blob.count // Real_64_bytes
		end

	make_zero (a_dimension: INTEGER)
			-- Create zero vector of given dimension
		require
			positive_dimension: a_dimension > 0
		do
			create values.make_filled (0.0, 1, a_dimension)
		ensure
			dimension_set: dimension = a_dimension
			all_zero: across 1 |..| dimension as i all item (i) = 0.0 end
		end

feature -- Access

	dimension: INTEGER
			-- Number of elements in vector
		do
			Result := values.count
		end

	item alias "[]" (a_index: INTEGER): REAL_64 assign put
			-- Element at index (1-based)
		require
			valid_index: a_index >= 1 and a_index <= dimension
		do
			Result := values [a_index]
		end

	values: ARRAY [REAL_64]
			-- Underlying array of values

feature -- Element change

	put (a_value: REAL_64; a_index: INTEGER)
			-- Set element at index
		require
			valid_index: a_index >= 1 and a_index <= dimension
			no_nan: not a_value.is_nan
			no_infinity: not a_value.is_positive_infinity and not a_value.is_negative_infinity
		do
			values [a_index] := a_value
		ensure
			value_set: item (a_index) = a_value
			dimension_unchanged: dimension = old dimension
		end

feature -- Conversion

	to_blob: MANAGED_POINTER
			-- Convert to BLOB for SQLite storage (IEEE 754 double-precision, little-endian)
		local
			i: INTEGER
		do
			create Result.make (dimension * Real_64_bytes)
			from i := 1 until i > dimension loop
				Result.put_real_64_le (values [i], (i - 1) * Real_64_bytes)
				i := i + 1
			variant
				dimension - i + 1
			end
		ensure
			blob_size_correct: Result.count = dimension * Real_64_bytes
			blob_not_void: Result /= Void
		end

	to_array: ARRAY [REAL_64]
			-- Copy of values as array
		do
			Result := values.twin
		ensure
			same_dimension: Result.count = dimension
			values_match: across 1 |..| dimension as i all Result [i] = item (i) end
		end

feature -- Mathematical operations

	magnitude: REAL_64
			-- Euclidean norm (L2 norm) of vector
		local
			sum: REAL_64
			i: INTEGER
		do
			from i := 1 until i > dimension loop
				sum := sum + values [i] * values [i]
				i := i + 1
			variant
				dimension - i + 1
			end
			Result := {DOUBLE_MATH}.sqrt (sum)
		ensure
			non_negative: Result >= 0.0
			zero_iff_zero_vector: (Result = 0.0) = is_zero
		end

	dot_product (a_other: SIMPLE_SQL_VECTOR): REAL_64
			-- Dot product with another vector
		require
			same_dimension: a_other.dimension = dimension
		local
			i: INTEGER
		do
			from i := 1 until i > dimension loop
				Result := Result + values [i] * a_other.values [i]
				i := i + 1
			variant
				dimension - i + 1
			end
		ensure
			symmetric: Result = a_other.dot_product (Current)
		end

	normalized: SIMPLE_SQL_VECTOR
			-- Unit vector in same direction (magnitude = 1)
		local
			mag: REAL_64
			norm_values: ARRAY [REAL_64]
			i: INTEGER
		do
			mag := magnitude
			create norm_values.make_filled (0.0, 1, dimension)
			if mag > 0.0 then
				from i := 1 until i > dimension loop
					norm_values [i] := values [i] / mag
					i := i + 1
				variant
					dimension - i + 1
				end
			end
			create Result.make_from_array (norm_values)
		ensure
			same_dimension: Result.dimension = dimension
			unit_magnitude_when_nonzero: magnitude > 0.0 implies (Result.magnitude - 1.0).abs < 1.0e-10
			zero_when_zero: magnitude = 0.0 implies Result.is_zero
		end

	add (a_other: SIMPLE_SQL_VECTOR): SIMPLE_SQL_VECTOR
			-- Vector addition
		require
			same_dimension: a_other.dimension = dimension
		local
			result_values: ARRAY [REAL_64]
			i: INTEGER
		do
			create result_values.make_filled (0.0, 1, dimension)
			from i := 1 until i > dimension loop
				result_values [i] := values [i] + a_other.values [i]
				i := i + 1
			variant
				dimension - i + 1
			end
			create Result.make_from_array (result_values)
		ensure
			same_dimension: Result.dimension = dimension
			commutative: Result ~ a_other.add (Current)
		end

	subtract (a_other: SIMPLE_SQL_VECTOR): SIMPLE_SQL_VECTOR
			-- Vector subtraction
		require
			same_dimension: a_other.dimension = dimension
		local
			result_values: ARRAY [REAL_64]
			i: INTEGER
		do
			create result_values.make_filled (0.0, 1, dimension)
			from i := 1 until i > dimension loop
				result_values [i] := values [i] - a_other.values [i]
				i := i + 1
			variant
				dimension - i + 1
			end
			create Result.make_from_array (result_values)
		ensure
			same_dimension: Result.dimension = dimension
			self_minus_self_is_zero: a_other ~ Current implies Result.is_zero
		end

	scale (a_factor: REAL_64): SIMPLE_SQL_VECTOR
			-- Scalar multiplication
		require
			no_nan: not a_factor.is_nan
			no_infinity: not a_factor.is_positive_infinity and not a_factor.is_negative_infinity
		local
			result_values: ARRAY [REAL_64]
			i: INTEGER
		do
			create result_values.make_filled (0.0, 1, dimension)
			from i := 1 until i > dimension loop
				result_values [i] := values [i] * a_factor
				i := i + 1
			variant
				dimension - i + 1
			end
			create Result.make_from_array (result_values)
		ensure
			same_dimension: Result.dimension = dimension
			scale_by_zero_is_zero: a_factor = 0.0 implies Result.is_zero
			scale_by_one_is_equal: a_factor = 1.0 implies Result ~ Current
		end

feature -- Comparison

	is_equal (other: like Current): BOOLEAN
			-- Are vectors equal (within floating point tolerance)?
			-- Uses hybrid tolerance: max(absolute, relative * max(|a|, |b|))
		local
			i: INTEGER
			diff, max_abs, threshold: REAL_64
		do
			if dimension = other.dimension then
				Result := True
				from i := 1 until i > dimension or not Result loop
					diff := (values [i] - other.values [i]).abs
					max_abs := values [i].abs.max (other.values [i].abs)
					threshold := Absolute_tolerance.max (Relative_tolerance * max_abs)
					Result := diff <= threshold
					i := i + 1
				variant
					dimension - i + 1
				end
			end
		ensure then
			reflexive: other = Current implies Result
			symmetric: Result implies other.is_equal (Current)
		end

	is_zero: BOOLEAN
			-- Is this a zero vector?
			-- Uses absolute tolerance (relative tolerance meaningless near zero)
		local
			i: INTEGER
		do
			Result := True
			from i := 1 until i > dimension or not Result loop
				Result := values [i].abs < Absolute_tolerance
				i := i + 1
			variant
				dimension - i + 1
			end
		ensure
			zero_magnitude: Result implies magnitude < Absolute_tolerance
		end

feature -- Output

	out: STRING
			-- String representation
		local
			i: INTEGER
		do
			create Result.make (dimension * 10)
			Result.append ("[")
			from i := 1 until i > dimension loop
				if i > 1 then
					Result.append (", ")
				end
				Result.append (values [i].out)
				i := i + 1
			variant
				dimension - i + 1
			end
			Result.append ("]")
		ensure then
			starts_with_bracket: Result.starts_with ("[")
			ends_with_bracket: Result.ends_with ("]")
			not_empty: not Result.is_empty
		end

feature {NONE} -- Constants

	Real_64_bytes: INTEGER = 8
			-- Size of REAL_64 in bytes (IEEE 754 double-precision)

	Absolute_tolerance: REAL_64 = 1.0e-10
			-- Absolute tolerance for near-zero comparisons

	Relative_tolerance: REAL_64 = 1.0e-10
			-- Relative tolerance for scaling with magnitude

invariant
	values_exist: values /= Void
	positive_dimension: dimension > 0
	one_based_array: values.lower = 1
	consistent_upper_bound: values.upper = dimension
	no_nan_values: across 1 |..| dimension as i all not values [i].is_nan end
	no_infinite_values: across 1 |..| dimension as i all not values [i].is_positive_infinity and not values [i].is_negative_infinity end

end
