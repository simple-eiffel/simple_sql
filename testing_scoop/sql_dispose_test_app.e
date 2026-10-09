note
	description: "[
		SCOOP proof that SIMPLE_SQL_DATABASE connections left to the garbage
		collector are disposed safely whichever thread collects them (target
		simple_sql_scoop_test).

		An HTTP server under SCOOP serves each request on a processor of its
		own; a handler that opens a connection and never closes it leaves it
		to the collector, and the processor that opened it may be gone by
		then. `dispose' then runs on another thread, in the middle of a
		collection. bible_htmx died exactly there (2026-10-09):
		SIMPLE_SQL_DATABASE.dispose -> SQLITE_DATABASE.is_closed,
		precondition `is_accessible' violated.
		  1. 50 connections opened, queried and dropped on a worker processor
		     that is itself dropped, then collected from the root;
		  2. 50 connections opened, queried and dropped on the root, then
		     collected on the root;
		  3. 50 more dropped on the root, collected by a worker processor.
		The process must survive each collection, find no connection left in
		memory, and exit with status 0.
	]"

class
	SQL_DISPOSE_TEST_APP

create
	make

feature {NONE} -- Initialization

	make
		do
			print ("simple_sql SCOOP dispose proof%N%N")
			create_database
			report ("a worker opened, queried and dropped 50 connections, then was dropped", open_and_drop_on_a_worker = 50)
			collect
			report ("the root's collection disposed them (" + live_connections.out + " left) and the process lives", live_connections = 0)
			report ("the root opened, queried and dropped 50 connections", open_and_drop_here = 50)
			collect
			report ("the owning thread's collection disposed them (" + live_connections.out + " left) and the process lives", live_connections = 0)
			report ("the root opened, queried and dropped 50 more", open_and_drop_here = 50)
			collect_on_a_worker
			report ("a worker's collection disposed them (" + live_connections.out + " left) and the process lives", live_connections = 0)
			print ("%NResults: " + passed.out + " passed, " + failed.out + " failed%N")
			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
			io.output.flush
		end

feature {NONE} -- Steps

	Database_path: STRING_8 = "simple_sql_dispose_proof.db"

	create_database
			-- A file database whose table `t' holds one row.
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			create l_db.make (Database_path)
			l_db.execute ("CREATE TABLE IF NOT EXISTS t (x INTEGER)")
			l_db.execute ("DELETE FROM t")
			l_db.execute ("INSERT INTO t VALUES (42)")
			l_db.close
		end

	open_and_drop_on_a_worker: INTEGER
			-- 50 connections on a worker processor that is dropped on return.
		local
			l_worker: separate SQL_DISPOSE_WORKER
		do
			create l_worker
			Result := open_and_drop (l_worker)
		end

	open_and_drop (a_worker: separate SQL_DISPOSE_WORKER): INTEGER
			-- Have `a_worker' open and drop 50 connections; wait for it.
		do
			a_worker.open_and_drop (Database_path, 50)
			Result := a_worker.opened
		end

	open_and_drop_here: INTEGER
			-- 50 connections opened, queried and dropped on this processor.
		local
			l_db: SIMPLE_SQL_DATABASE
			i: INTEGER
		do
			from i := 1 until i > 50 loop
				create l_db.make (Database_path)
				if not l_db.query ("SELECT x FROM t").is_empty then
					Result := Result + 1
				end
				i := i + 1
			end
		end

	collect
			-- Full collections around a pause, so dropped processors wind down and
			-- every dropped object is disposed.
		local
			l_memory: MEMORY
		do
			create l_memory
			l_memory.full_collect;
			(create {EXECUTION_ENVIRONMENT}).sleep (500_000_000)
			l_memory.full_collect
			l_memory.full_collect
		end

	collect_on_a_worker
		local
			l_worker: separate SQL_DISPOSE_WORKER
		do
			create l_worker
			worker_collect (l_worker)
		end

	worker_collect (a_worker: separate SQL_DISPOSE_WORKER)
		do
			a_worker.collect
		end

	live_connections: INTEGER
			-- SIMPLE_SQL_DATABASE objects still in memory.
		do
			Result := (create {MEMORY}).objects_instance_of_type (({SIMPLE_SQL_DATABASE}).type_id).count
		end

feature {NONE} -- Reporting

	passed, failed: INTEGER

	report (a_name: STRING_8; a_ok: BOOLEAN)
		do
			if a_ok then
				passed := passed + 1
				print ("  PASS: " + a_name + "%N")
			else
				failed := failed + 1
				print ("  FAIL: " + a_name + "%N")
			end
			io.output.flush
		end

end
