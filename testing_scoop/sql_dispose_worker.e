note
	description: "[
		Opens SIMPLE_SQL_DATABASE connections on its own processor, queries
		each once and drops it, as a request handler of an HTTP server does,
		for SQL_DISPOSE_TEST_APP.
	]"

class
	SQL_DISPOSE_WORKER

feature -- Access

	opened: INTEGER
			-- Connections opened, queried and dropped so far.

feature -- Basic operations

	open_and_drop (a_path: separate READABLE_STRING_8; a_count: INTEGER)
			-- Open `a_count' connections to `a_path', query each, leave them to the collector.
		require
			positive: a_count > 0
		local
			l_path: STRING_8
			i: INTEGER
		do
			create l_path.make_from_separate (a_path)
			from i := 1 until i > a_count loop
				if open_one (l_path) then
					opened := opened + 1
				end
				i := i + 1
			end
		end

	collect
			-- Full collections run from this processor's thread.
		do
			(create {MEMORY}).full_collect;
			(create {MEMORY}).full_collect
		end

feature {NONE} -- Implementation

	open_one (a_path: STRING_8): BOOLEAN
			-- Open a connection, read the one row of `t', drop the connection unclosed.
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			create l_db.make (a_path)
			Result := not l_db.query ("SELECT x FROM t").is_empty
		end

end
