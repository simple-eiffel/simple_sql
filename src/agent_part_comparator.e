note
	description: "[
		An agent-based partial order comparator that adapts comparison predicates
		to the PART_COMPARATOR interface.
		Wraps a PREDICATE agent to delegate less-than ordering decisions at runtime.
		Bridges agent-based comparisons to SORTER classes within the simple_sql library.
	]"
	purpose: "Adapt comparison predicate agents to the PART_COMPARATOR interface for sorting"
	collaborators: "PART_COMPARATOR, PREDICATE"
	design_pattern: "Adapter"
	author: "Jimmy J. Johnson"
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
		note
			semantic_role: "[
				Captures the comparison predicate agent
				for delegation to sorting infrastructure.
			]"
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
		note
			semantic_role: "[
				Delegates ordering comparison to the
				captured agent predicate for runtime
				less-than decisions.
			]"
		do
			Result := less_than_agent.item ([u, v])
		end

invariant
	agent_exists: less_than_agent /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
