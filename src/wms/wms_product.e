note
	description: "WMS Product - SKU/item definition"

class
	WMS_PRODUCT

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_sku, a_name, a_description, a_unit: READABLE_STRING_8;
			a_min_stock: INTEGER; a_deleted_at: detachable READABLE_STRING_8)
		do
			id := a_id
			sku := a_sku.to_string_8
			name := a_name.to_string_8
			description := a_description.to_string_8
			unit_of_measure := a_unit.to_string_8
			min_stock_level := a_min_stock
			if attached a_deleted_at as al_d then
				deleted_at := al_d.to_string_8
			end
		end

	make_new (a_sku, a_name, a_unit: READABLE_STRING_8)
		require
			sku_not_empty: not a_sku.is_empty
			name_not_empty: not a_name.is_empty
		do
			sku := a_sku.to_string_8
			name := a_name.to_string_8
			description := ""
			unit_of_measure := a_unit.to_string_8
			min_stock_level := 0
		ensure
			is_new: is_new
		end

feature -- Access

	id: INTEGER_64

	sku: STRING_8

	name: STRING_8

	description: STRING_8

	unit_of_measure: STRING_8

	min_stock_level: INTEGER

	deleted_at: detachable STRING_8

feature -- Status

	is_new: BOOLEAN
		do
			Result := id = 0
		end

	is_deleted: BOOLEAN
		do
			Result := attached deleted_at
		end

feature -- Modification

	set_id (a_id: INTEGER_64)
		require
			was_new: is_new
			valid_id: a_id > 0
		do
			id := a_id
		ensure
			not_new: not is_new
		end

	set_description (a_desc: READABLE_STRING_8)
		do
			description := a_desc.to_string_8
		end

	set_min_stock_level (a_level: INTEGER)
		require
			non_negative: a_level >= 0
		do
			min_stock_level := a_level
		end

invariant
	sku_not_empty: not sku.is_empty
	name_not_empty: not name.is_empty

end
