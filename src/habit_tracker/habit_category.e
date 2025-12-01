note
	description: "A category for organizing habits (Health, Productivity, etc.)"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	HABIT_CATEGORY

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_user_id: INTEGER_64; a_name: READABLE_STRING_8;
			a_color: READABLE_STRING_8; a_icon: READABLE_STRING_8; a_sort_order: INTEGER)
			-- Initialize from database row.
		require
			name_not_empty: not a_name.is_empty
			valid_user: a_user_id > 0
		do
			id := a_id
			user_id := a_user_id
			name := a_name.to_string_8
			color := a_color.to_string_8
			icon := a_icon.to_string_8
			sort_order := a_sort_order
		ensure
			id_set: id = a_id
			user_id_set: user_id = a_user_id
			name_set: name.same_string (a_name)
		end

	make_new (a_user_id: INTEGER_64; a_name: READABLE_STRING_8)
			-- Create a new category with defaults.
		require
			valid_user: a_user_id > 0
			name_not_empty: not a_name.is_empty
		do
			id := 0
			user_id := a_user_id
			name := a_name.to_string_8
			color := "#6366F1" -- Default indigo
			icon := "folder"   -- Default icon
			sort_order := 0
		ensure
			id_zero: id = 0
			user_id_set: user_id = a_user_id
			name_set: name.same_string (a_name)
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier (0 if not yet saved).

	user_id: INTEGER_64
			-- Owner of this category.

	name: STRING_8
			-- Category name (e.g., "Health", "Productivity").

	color: STRING_8
			-- Hex color code for display (e.g., "#6366F1").

	icon: STRING_8
			-- Icon identifier (e.g., "heart", "briefcase", "book").

	sort_order: INTEGER
			-- Order for display (lower = first).

feature -- Status

	is_new: BOOLEAN
			-- Has this category not yet been saved to database?
		do
			Result := id = 0
		end

feature -- Modification

	set_id (a_id: INTEGER_64)
			-- Set the ID (called after insert).
		require
			was_new: id = 0
			valid_id: a_id > 0
		do
			id := a_id
		ensure
			id_set: id = a_id
		end

	set_name (a_name: READABLE_STRING_8)
			-- Update category name.
		require
			not_empty: not a_name.is_empty
		do
			name := a_name.to_string_8
		ensure
			name_set: name.same_string (a_name)
		end

	set_color (a_color: READABLE_STRING_8)
			-- Update color code.
		require
			not_empty: not a_color.is_empty
		do
			color := a_color.to_string_8
		ensure
			color_set: color.same_string (a_color)
		end

	set_icon (a_icon: READABLE_STRING_8)
			-- Update icon identifier.
		require
			not_empty: not a_icon.is_empty
		do
			icon := a_icon.to_string_8
		ensure
			icon_set: icon.same_string (a_icon)
		end

	set_sort_order (a_order: INTEGER)
			-- Update sort order.
		do
			sort_order := a_order
		ensure
			sort_order_set: sort_order = a_order
		end

feature -- Predefined Categories (Factory)

	default_categories: ARRAYED_LIST [TUPLE [name: STRING_8; color: STRING_8; icon: STRING_8]]
			-- Standard category templates.
		once
			create Result.make (6)
			Result.extend (["Health", "#10B981", "heart"])           -- Green
			Result.extend (["Productivity", "#3B82F6", "briefcase"]) -- Blue
			Result.extend (["Learning", "#8B5CF6", "book"])          -- Purple
			Result.extend (["Social", "#F59E0B", "users"])           -- Amber
			Result.extend (["Finance", "#06B6D4", "dollar"])         -- Cyan
			Result.extend (["Mindfulness", "#EC4899", "lotus"])      -- Pink
		end

invariant
	name_not_empty: not name.is_empty
	color_not_empty: not color.is_empty
	icon_not_empty: not icon.is_empty
	valid_user_id: user_id > 0
	id_non_negative: id >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
