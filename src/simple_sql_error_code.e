note
	description: "[
		Enumeration of SQLite primary and extended result codes as named constants.
		Maps integer error codes to human-readable SQLITE_* names and classifies
		them as success or error.
		Serves as the canonical code reference for simple_sql error handling.
	]"
	purpose: "Define and name-resolve SQLite result codes for error classification"
	collaborators: ""
	author: "Jimmy J. Johnson"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_ERROR_CODE

feature -- Primary Result Codes

	ok: INTEGER = 0
			-- Successful result

	error: INTEGER = 1
			-- Generic error

	internal: INTEGER = 2
			-- Internal logic error in SQLite

	perm: INTEGER = 3
			-- Access permission denied

	abort: INTEGER = 4
			-- Callback routine requested an abort

	busy: INTEGER = 5
			-- The database file is locked

	locked: INTEGER = 6
			-- A table in the database is locked

	nomem: INTEGER = 7
			-- A malloc() failed

	readonly: INTEGER = 8
			-- Attempt to write a readonly database

	interrupt: INTEGER = 9
			-- Operation terminated by sqlite3_interrupt()

	ioerr: INTEGER = 10
			-- Some kind of disk I/O error occurred

	corrupt: INTEGER = 11
			-- The database disk image is malformed

	notfound: INTEGER = 12
			-- Unknown opcode in sqlite3_file_control()

	full: INTEGER = 13
			-- Insertion failed because database is full

	cantopen: INTEGER = 14
			-- Unable to open the database file

	protocol: INTEGER = 15
			-- Database lock protocol error

	empty: INTEGER = 16
			-- Internal use only

	schema: INTEGER = 17
			-- The database schema changed

	toobig: INTEGER = 18
			-- String or BLOB exceeds size limit

	constraint: INTEGER = 19
			-- Abort due to constraint violation

	mismatch: INTEGER = 20
			-- Data type mismatch

	misuse: INTEGER = 21
			-- Library used incorrectly

	nolfs: INTEGER = 22
			-- Uses OS features not supported on host

	auth: INTEGER = 23
			-- Authorization denied

	format: INTEGER = 24
			-- Not used

	range: INTEGER = 25
			-- 2nd parameter to sqlite3_bind out of range

	notadb: INTEGER = 26
			-- File opened that is not a database file

	notice: INTEGER = 27
			-- Notifications from sqlite3_log()

	warning: INTEGER = 28
			-- Warnings from sqlite3_log()

	row: INTEGER = 100
			-- sqlite3_step() has another row ready

	done: INTEGER = 101
			-- sqlite3_step() has finished executing

feature -- Extended Result Codes (Common)

	error_missing_collseq: INTEGER = 257
			-- SQLITE_ERROR_MISSING_COLLSEQ

	error_retry: INTEGER = 513
			-- SQLITE_ERROR_RETRY

	error_snapshot: INTEGER = 769
			-- SQLITE_ERROR_SNAPSHOT

	ioerr_read: INTEGER = 266
			-- SQLITE_IOERR_READ

	ioerr_short_read: INTEGER = 522
			-- SQLITE_IOERR_SHORT_READ

	ioerr_write: INTEGER = 778
			-- SQLITE_IOERR_WRITE

	ioerr_fsync: INTEGER = 1034
			-- SQLITE_IOERR_FSYNC

	ioerr_lock: INTEGER = 3850
			-- SQLITE_IOERR_LOCK

	ioerr_close: INTEGER = 4106
			-- SQLITE_IOERR_CLOSE

	locked_sharedcache: INTEGER = 262
			-- SQLITE_LOCKED_SHAREDCACHE

	busy_recovery: INTEGER = 261
			-- SQLITE_BUSY_RECOVERY

	busy_snapshot: INTEGER = 517
			-- SQLITE_BUSY_SNAPSHOT

	busy_timeout: INTEGER = 773
			-- SQLITE_BUSY_TIMEOUT

	cantopen_notempdir: INTEGER = 270
			-- SQLITE_CANTOPEN_NOTEMPDIR

	cantopen_isdir: INTEGER = 526
			-- SQLITE_CANTOPEN_ISDIR

	cantopen_fullpath: INTEGER = 782
			-- SQLITE_CANTOPEN_FULLPATH

	corrupt_vtab: INTEGER = 267
			-- SQLITE_CORRUPT_VTAB

	corrupt_sequence: INTEGER = 523
			-- SQLITE_CORRUPT_SEQUENCE

	readonly_recovery: INTEGER = 264
			-- SQLITE_READONLY_RECOVERY

	readonly_cantlock: INTEGER = 520
			-- SQLITE_READONLY_CANTLOCK

	readonly_rollback: INTEGER = 776
			-- SQLITE_READONLY_ROLLBACK

	readonly_dbmoved: INTEGER = 1032
			-- SQLITE_READONLY_DBMOVED

	abort_rollback: INTEGER = 516
			-- SQLITE_ABORT_ROLLBACK

	constraint_check: INTEGER = 275
			-- SQLITE_CONSTRAINT_CHECK

	constraint_commithook: INTEGER = 531
			-- SQLITE_CONSTRAINT_COMMITHOOK

	constraint_foreignkey: INTEGER = 787
			-- SQLITE_CONSTRAINT_FOREIGNKEY

	constraint_function: INTEGER = 1043
			-- SQLITE_CONSTRAINT_FUNCTION

	constraint_notnull: INTEGER = 1299
			-- SQLITE_CONSTRAINT_NOTNULL

	constraint_primarykey: INTEGER = 1555
			-- SQLITE_CONSTRAINT_PRIMARYKEY

	constraint_trigger: INTEGER = 1811
			-- SQLITE_CONSTRAINT_TRIGGER

	constraint_unique: INTEGER = 2067
			-- SQLITE_CONSTRAINT_UNIQUE

	constraint_vtab: INTEGER = 2323
			-- SQLITE_CONSTRAINT_VTAB

	constraint_rowid: INTEGER = 2579
			-- SQLITE_CONSTRAINT_ROWID

	notice_recover_wal: INTEGER = 283
			-- SQLITE_NOTICE_RECOVER_WAL

	notice_recover_rollback: INTEGER = 539
			-- SQLITE_NOTICE_RECOVER_ROLLBACK

	warning_autoindex: INTEGER = 284
			-- SQLITE_WARNING_AUTOINDEX

	auth_user: INTEGER = 279
			-- SQLITE_AUTH_USER

feature -- Query

	name (a_code: INTEGER): STRING_8
			-- Human-readable name for error code
		note
			semantic_role: "[
				Maps integer error codes to their
				SQLITE_* symbolic constant names.
			]"
		do
			inspect a_code
			when ok then Result := "SQLITE_OK"
			when error then Result := "SQLITE_ERROR"
			when internal then Result := "SQLITE_INTERNAL"
			when perm then Result := "SQLITE_PERM"
			when abort then Result := "SQLITE_ABORT"
			when busy then Result := "SQLITE_BUSY"
			when locked then Result := "SQLITE_LOCKED"
			when nomem then Result := "SQLITE_NOMEM"
			when readonly then Result := "SQLITE_READONLY"
			when interrupt then Result := "SQLITE_INTERRUPT"
			when ioerr then Result := "SQLITE_IOERR"
			when corrupt then Result := "SQLITE_CORRUPT"
			when notfound then Result := "SQLITE_NOTFOUND"
			when full then Result := "SQLITE_FULL"
			when cantopen then Result := "SQLITE_CANTOPEN"
			when protocol then Result := "SQLITE_PROTOCOL"
			when empty then Result := "SQLITE_EMPTY"
			when schema then Result := "SQLITE_SCHEMA"
			when toobig then Result := "SQLITE_TOOBIG"
			when constraint then Result := "SQLITE_CONSTRAINT"
			when mismatch then Result := "SQLITE_MISMATCH"
			when misuse then Result := "SQLITE_MISUSE"
			when nolfs then Result := "SQLITE_NOLFS"
			when auth then Result := "SQLITE_AUTH"
			when format then Result := "SQLITE_FORMAT"
			when range then Result := "SQLITE_RANGE"
			when notadb then Result := "SQLITE_NOTADB"
			when notice then Result := "SQLITE_NOTICE"
			when warning then Result := "SQLITE_WARNING"
			when row then Result := "SQLITE_ROW"
			when done then Result := "SQLITE_DONE"
			when constraint_check then Result := "SQLITE_CONSTRAINT_CHECK"
			when constraint_foreignkey then Result := "SQLITE_CONSTRAINT_FOREIGNKEY"
			when constraint_notnull then Result := "SQLITE_CONSTRAINT_NOTNULL"
			when constraint_primarykey then Result := "SQLITE_CONSTRAINT_PRIMARYKEY"
			when constraint_unique then Result := "SQLITE_CONSTRAINT_UNIQUE"
			when busy_recovery then Result := "SQLITE_BUSY_RECOVERY"
			when busy_snapshot then Result := "SQLITE_BUSY_SNAPSHOT"
			when busy_timeout then Result := "SQLITE_BUSY_TIMEOUT"
			when locked_sharedcache then Result := "SQLITE_LOCKED_SHAREDCACHE"
			when readonly_recovery then Result := "SQLITE_READONLY_RECOVERY"
			when readonly_cantlock then Result := "SQLITE_READONLY_CANTLOCK"
			when readonly_rollback then Result := "SQLITE_READONLY_ROLLBACK"
			when readonly_dbmoved then Result := "SQLITE_READONLY_DBMOVED"
			else
				Result := "SQLITE_UNKNOWN_" + a_code.out
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	is_success (a_code: INTEGER): BOOLEAN
			-- Is this a success code?
		note
			semantic_role: "[
				Classifies result codes as successful
				(OK, DONE, ROW).
			]"
		do
			Result := a_code = ok or a_code = done or a_code = row
		end

	is_error (a_code: INTEGER): BOOLEAN
			-- Is this an error code?
		note
			semantic_role: "[
				Classifies result codes as errors
				(anything not success).
			]"
		do
			Result := not is_success (a_code)
		end

	primary_code (a_extended_code: INTEGER): INTEGER
			-- Extract primary result code from extended code
			-- Extended codes have primary code in lower 8 bits
		note
			semantic_role: "[
				Bit-masks extended code to extract the
				primary 8-bit result code.
			]"
		do
			Result := a_extended_code & 0xFF
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		simple_sql - High-level SQLite API for Eiffel
		https://github.com/simple-eiffel/simple_sql
	]"

end
