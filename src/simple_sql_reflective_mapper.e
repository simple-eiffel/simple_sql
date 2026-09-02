note
	description: "[
		A reflection-based mapper for bidirectional object-to-row conversion.
		Converts Eiffel objects to column/value hash tables for INSERT/UPDATE
		and populates object fields from SIMPLE_SQL_ROW data using runtime
		reflection with optional snake_case column naming.
		Provides lightweight ORM capability for the simple_sql library.
	]"
	purpose: "Map objects to database rows and back using runtime reflection"
	collaborators: "SIMPLE_SQL_ROW, SIMPLE_SQL_RESULT, SIMPLE_REFLECTED_OBJECT, SIMPLE_FIELD_INFO"
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_REFLECTIVE_MAPPER

create
	make

feature {NONE} -- Initialization

	make
			-- Create reflective mapper.
		note
			semantic_role: "[
				Initializes mapper with snake_case
				column naming enabled by default.
			]"
		do
			snake_case_columns := True
		ensure
			snake_case_enabled: snake_case_columns
		end

feature -- Settings

	snake_case_columns: BOOLEAN
			-- Convert field names to snake_case for column names?
			-- e.g., firstName -> first_name

	set_snake_case_columns (a_value: BOOLEAN)
			-- Set whether to use snake_case for column names.
		note
			semantic_role: "[
				Configures the field-to-column naming
				convention.
			]"
			modifies: "snake_case_columns"
		do
			snake_case_columns := a_value
		ensure
			set: snake_case_columns = a_value
		end

feature -- Object to Row Mapping

	object_to_hash (a_object: ANY): HASH_TABLE [detachable ANY, STRING]
			-- Convert object fields to hash table for SQL operations.
			-- Keys are column names, values are field values.
		note
			semantic_role: "[
				Reflects object fields into a column-name
				and value hash for SQL generation.
			]"
		require
			object_exists: a_object /= Void
		local
			l_reflected: SIMPLE_REFLECTED_OBJECT
			l_field: SIMPLE_FIELD_INFO
			l_col_name: STRING
			l_value: detachable ANY
			i: INTEGER
		do
			create Result.make (10)
			create l_reflected.make (a_object)
			from
				i := 1
			until
				i > l_reflected.type_info.fields.count
			loop
				l_field := l_reflected.type_info.fields [i]
				l_col_name := field_to_column_name (l_field.name.to_string_8)
				l_value := l_field.value (a_object)
				Result.put (convert_to_sql_value (l_value), l_col_name)
				i := i + 1
			end
		ensure
			result_exists: Result /= Void
		end

	create_table_sql (a_prototype: ANY; a_table_name: STRING): STRING
			-- Generate CREATE TABLE SQL from object fields.
		note
			semantic_role: "[
				Generates DDL from reflected field types
				with automatic type mapping.
			]"
		require
			prototype_exists: a_prototype /= Void
			table_name_not_empty: not a_table_name.is_empty
		local
			l_reflected: SIMPLE_REFLECTED_OBJECT
			l_field: SIMPLE_FIELD_INFO
			l_col_name: STRING
			i: INTEGER
		do
			create Result.make (200)
			Result.append ("CREATE TABLE IF NOT EXISTS ")
			Result.append (a_table_name)
			Result.append (" (")

			create l_reflected.make (a_prototype)
			from
				i := 1
			until
				i > l_reflected.type_info.fields.count
			loop
				if i > 1 then
					Result.append (", ")
				end
				l_field := l_reflected.type_info.fields [i]
				l_col_name := field_to_column_name (l_field.name.to_string_8)
				Result.append (l_col_name)
				Result.append (" ")
				Result.append (sql_type_for_field (l_field))
				i := i + 1
			end

			Result.append (")")
		ensure
			result_not_empty: not Result.is_empty
		end

feature -- Row to Object Mapping

	row_to_object (a_row: SIMPLE_SQL_ROW; a_prototype: ANY): ANY
			-- Create new object from row data using prototype.
			-- Sets fields that match column names.
		note
			semantic_role: "[
				Clones prototype and populates fields
				from matching database columns.
			]"
		require
			row_exists: a_row /= Void
			prototype_exists: a_prototype /= Void
		local
			l_result: ANY
			l_reflected: SIMPLE_REFLECTED_OBJECT
			l_field: SIMPLE_FIELD_INFO
			l_col_name: STRING
			l_value: detachable ANY
			i: INTEGER
		do
			l_result := a_prototype.twin
			create l_reflected.make (l_result)
			from
				i := 1
			until
				i > l_reflected.type_info.fields.count
			loop
				l_field := l_reflected.type_info.fields [i]
				l_col_name := field_to_column_name (l_field.name.to_string_8)
				if a_row.has_column (l_col_name) then
					l_value := a_row.column_value (l_col_name)
					set_field_value (l_result, l_field, l_value)
				end
				i := i + 1
			end
			Result := l_result
		ensure
			result_exists: Result /= Void
		end

feature -- Bulk Mapping

	rows_to_objects (a_result: SIMPLE_SQL_RESULT; a_prototype: ANY): ARRAYED_LIST [ANY]
			-- Convert all rows to objects.
		note
			semantic_role: "[
				Maps each result row to an object via
				row_to_object.
			]"
		require
			result_exists: a_result /= Void
			prototype_exists: a_prototype /= Void
		do
			create Result.make (a_result.count)
			across a_result.rows as ic loop
				Result.extend (row_to_object (ic, a_prototype))
			end
		ensure
			result_exists: Result /= Void
			count_matches: Result.count = a_result.count
		end

feature {NONE} -- Implementation

	field_to_column_name (a_field_name: STRING): STRING
			-- Convert field name to column name.
		note
			semantic_role: "[
				Applies snake_case conversion if
				enabled, otherwise returns a copy.
			]"
		do
			if snake_case_columns then
				Result := to_snake_case (a_field_name)
			else
				Result := a_field_name.twin
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	to_snake_case (a_name: STRING): STRING
			-- Convert camelCase or PascalCase to snake_case.
		note
			semantic_role: "[
				Inserts underscores before uppercase
				letters and lowercases the result.
			]"
		local
			i: INTEGER
			c: CHARACTER
		do
			create Result.make (a_name.count + 5)
			from
				i := 1
			until
				i > a_name.count
			loop
				c := a_name.item (i)
				if c.is_upper then
					if i > 1 then
						Result.append_character ('_')
					end
					Result.append_character (c.as_lower)
				else
					Result.append_character (c)
				end
				i := i + 1
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	sql_type_for_field (a_field: SIMPLE_FIELD_INFO): STRING
			-- Determine SQL type for field based on its Eiffel type.
		note
			semantic_role: "[
				Maps Eiffel type names to SQLite
				column types.
			]"
		local
			l_type_name: STRING
			l_internal: INTERNAL
		do
			create l_internal
			l_type_name := l_internal.type_name_of_type (a_field.field_type_id).as_upper
			if l_type_name.has_substring ("INTEGER") then
				Result := "INTEGER"
			elseif l_type_name.has_substring ("REAL") or l_type_name.has_substring ("DOUBLE") then
				Result := "REAL"
			elseif l_type_name.has_substring ("BOOLEAN") then
				Result := "INTEGER"
			elseif l_type_name.has_substring ("STRING") then
				Result := "TEXT"
			else
				Result := "TEXT"
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	convert_to_sql_value (a_value: detachable ANY): detachable ANY
			-- Convert Eiffel value to SQL-compatible value.
		note
			semantic_role: "[
				Type-dispatches Eiffel values to
				SQLite-compatible representations.
			]"
		do
			if a_value = Void then
				Result := Void
			elseif attached {BOOLEAN} a_value as al_l_bool then
				Result := if al_l_bool then 1 else 0 end
			elseif attached {INTEGER} a_value as al_l_int then
				Result := al_l_int.to_integer_64
			elseif attached {INTEGER_64} a_value as al_l_int64 then
				Result := al_l_int64
			elseif attached {REAL_64} a_value as al_l_real then
				Result := al_l_real
			elseif attached {READABLE_STRING_GENERAL} a_value as al_l_str then
				Result := al_l_str.to_string_8
			else
				-- Convert other types to string representation
				Result := a_value.out
			end
		end

	set_field_value (a_object: ANY; a_field: SIMPLE_FIELD_INFO; a_value: detachable ANY)
			-- Set field value on object.
			-- Note: Uses reflection to set values.
		note
			semantic_role: "[
				Converts SQL value to appropriate type
				and sets via reflection.
			]"
		local
			l_converted: detachable ANY
		do
			-- Convert SQL value to appropriate Eiffel type
			l_converted := convert_from_sql_value (a_value, a_field)
			-- Attempt to set the field value using reflection
			a_field.set_value (a_object, l_converted)
		end

	convert_from_sql_value (a_value: detachable ANY; a_field: SIMPLE_FIELD_INFO): detachable ANY
			-- Convert SQL value to appropriate Eiffel type for field.
		note
			semantic_role: "[
				Reverse-maps SQLite values to Eiffel
				types using field type metadata.
			]"
		local
			l_type_name: STRING
			l_internal: INTERNAL
		do
			if a_value = Void then
				Result := Void
			else
				create l_internal
				l_type_name := l_internal.type_name_of_type (a_field.field_type_id).as_upper
				if l_type_name.has_substring ("BOOLEAN") then
					if attached {INTEGER_64} a_value as al_l_int then
						Result := al_l_int /= 0
					elseif attached {INTEGER} a_value as al_l_int32 then
						Result := al_l_int32 /= 0
					else
						Result := False
					end
				elseif l_type_name.has_substring ("INTEGER_64") then
					if attached {INTEGER_64} a_value as al_l_int64 then
						Result := al_l_int64
					elseif attached {INTEGER} a_value as al_l_int32 then
						Result := al_l_int32.to_integer_64
					end
				elseif l_type_name.has_substring ("INTEGER") then
					if attached {INTEGER_64} a_value as al_l_int64 then
						Result := al_l_int64.to_integer_32
					elseif attached {INTEGER} a_value as al_l_int32 then
						Result := al_l_int32
					end
				elseif l_type_name.has_substring ("REAL") or l_type_name.has_substring ("DOUBLE") then
					if attached {REAL_64} a_value as al_l_real then
						Result := al_l_real
					end
				elseif l_type_name.has_substring ("STRING") then
					if attached {READABLE_STRING_GENERAL} a_value as al_l_str then
						Result := al_l_str.to_string_32
					end
				else
					Result := a_value
				end
			end
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
