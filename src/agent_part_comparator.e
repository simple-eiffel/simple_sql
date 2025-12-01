note
	description: "[
		Agent-based partial order comparator.

		Wraps a comparison predicate to implement PART_COMPARATOR interface.
		Allows using agents with SORTER classes from base_extension library.

		Usage:
			create comparator.make (agent my_less_than)
			create sorter.make (comparator)
			sorter.sort (my_list)
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AGENT_PART_COMPARATOR [G]

inherit
	PART_COMPARATOR [G]

create
	make

feature {NONE} -- Initialization

	make (a_less_than: like less_than_agent)
			-- Create comparator using given agent
		require
			agent_not_void: a_less_than /= Void
		do
			less_than_agent := a_less_than
		ensure
			agent_set: less_than_agent = a_less_than
		end

feature -- Access

	less_than_agent: PREDICATE [G, G]
			-- Comparison predicate

feature -- Status report

	less_than (u, v: G): BOOLEAN
			-- Is `u' considered less than `v'?
		do
			Result := less_than_agent.item ([u, v])
		end

invariant
	agent_exists: less_than_agent /= Void

end
