# DATA-MIGRATOR - Ecosystem Integration

---

## simple_* Dependencies

### Required Libraries

| Library | Purpose | Integration Point |
|---------|---------|-------------------|
| simple_sql | Migration execution, schema introspection, export/import | SIMPLE_SQL_MIGRATION, SIMPLE_SQL_SCHEMA |
| simple_json | Configuration files, JSON output | Config parsing, status output |
| simple_cli | Command-line argument parsing | CLI interface |
| simple_file | Migration file handling | File reading/writing |

### Optional Libraries

| Library | Purpose | When Needed |
|---------|---------|-------------|
| simple_diff | Text-based schema diffing | When generating diff output |
| simple_csv | Data export/import | ETL pipeline, data seeding |
| simple_hash | Migration checksum verification | Integrity checking |
| simple_logger | Migration logging | Verbose mode, debugging |
| simple_datetime | Timestamp handling | Migration naming, timestamps |

---

## Integration Patterns

### simple_sql Migration Integration

**Purpose:** Core migration execution using simple_sql's built-in migration system

**Usage:**
```eiffel
class MIGRATOR_RUNNER

feature -- Migration Execution

    run_pending_migrations
            -- Execute all pending migrations
        local
            l_runner: SIMPLE_SQL_MIGRATION_RUNNER
            l_migrations: ARRAYED_LIST [SIMPLE_SQL_MIGRATION]
        do
            create l_runner.make (database)

            -- Add all migrations from files
            across load_migration_files as mig loop
                l_runner.add (mig)
            end

            -- Run pending
            if l_runner.migrate then
                last_version := l_runner.current_version
            else
                last_error := l_runner.last_error
                has_error := True
            end
        end

    rollback_migrations (a_steps: INTEGER)
            -- Rollback specified number of migrations
        local
            l_runner: SIMPLE_SQL_MIGRATION_RUNNER
        do
            create l_runner.make (database)
            load_all_migrations (l_runner)

            from
                steps_remaining := a_steps
            until
                steps_remaining = 0 or has_error
            loop
                if not l_runner.rollback then
                    last_error := l_runner.last_error
                    has_error := True
                end
                steps_remaining := steps_remaining - 1
            end
        end

feature {NONE} -- Implementation

    load_migration_files: ARRAYED_LIST [FILE_MIGRATION]
            -- Load migrations from ./migrations directory
        local
            l_dir: DIRECTORY
            l_file: PLAIN_TEXT_FILE
        do
            create Result.make (20)
            create l_dir.make_with_name (migrations_directory)

            across l_dir.linear_representation as entry loop
                if entry.ends_with (".sql") then
                    Result.extend (create {FILE_MIGRATION}.make_from_file (entry))
                end
            end

            -- Sort by version (filename prefix)
            Result.sort (agent compare_by_version)
        end

end

class FILE_MIGRATION

inherit
    SIMPLE_SQL_MIGRATION

feature {NONE} -- Initialization

    make_from_file (a_path: PATH)
            -- Parse migration file
        local
            l_content: STRING
            l_parser: MIGRATION_PARSER
        do
            l_content := read_file (a_path)
            create l_parser.make (l_content)

            version := l_parser.version
            description := l_parser.name
            up_sql := l_parser.up_sql
            down_sql := l_parser.down_sql
        end

feature -- Migration Interface

    up (a_db: SIMPLE_SQL_DATABASE)
        do
            a_db.execute (up_sql)
        end

    down (a_db: SIMPLE_SQL_DATABASE)
        do
            if attached down_sql as l_down then
                a_db.execute (l_down)
            end
        end

end
```

### simple_sql Schema Integration

**Purpose:** Schema introspection for comparison and diff generation

**Usage:**
```eiffel
class MIGRATOR_DIFF

feature -- Schema Comparison

    diff_schemas (a_source, a_target: SIMPLE_SQL_DATABASE): SCHEMA_DIFF
            -- Compare two database schemas
        local
            l_source_schema, l_target_schema: SIMPLE_SQL_SCHEMA
            l_source_tables, l_target_tables: ARRAYED_LIST [STRING]
        do
            l_source_schema := a_source.schema
            l_target_schema := a_target.schema

            l_source_tables := l_source_schema.tables
            l_target_tables := l_target_schema.tables

            create Result.make

            -- Find added tables (in target, not in source)
            across l_target_tables as t loop
                if not l_source_tables.has (t) then
                    Result.add_table (t, l_target_schema.table_info (t))
                end
            end

            -- Find removed tables (in source, not in target)
            across l_source_tables as t loop
                if not l_target_tables.has (t) then
                    Result.remove_table (t)
                end
            end

            -- Find modified tables (in both, but different)
            across l_source_tables as t loop
                if l_target_tables.has (t) then
                    diff_table (t,
                        l_source_schema.table_info (t),
                        l_target_schema.table_info (t),
                        Result)
                end
            end
        end

feature {NONE} -- Implementation

    diff_table (a_name: STRING; a_source, a_target: SIMPLE_SQL_TABLE_INFO;
            a_diff: SCHEMA_DIFF)
            -- Compare single table schemas
        local
            l_source_cols, l_target_cols: ARRAYED_LIST [SIMPLE_SQL_COLUMN_INFO]
        do
            l_source_cols := a_source.columns
            l_target_cols := a_target.columns

            -- Compare columns
            across l_target_cols as col loop
                if not has_column (l_source_cols, col.name) then
                    a_diff.add_column (a_name, col)
                elseif not same_column (find_column (l_source_cols, col.name), col) then
                    a_diff.modify_column (a_name, col)
                end
            end

            across l_source_cols as col loop
                if not has_column (l_target_cols, col.name) then
                    a_diff.remove_column (a_name, col.name)
                end
            end

            -- Compare indexes
            diff_indexes (a_name, a_source.indexes, a_target.indexes, a_diff)

            -- Compare foreign keys
            diff_foreign_keys (a_name, a_source.foreign_keys, a_target.foreign_keys, a_diff)
        end

end
```

### simple_cli Integration

**Purpose:** Command-line interface and argument parsing

**Usage:**
```eiffel
class DATA_MIGRATOR_CLI

inherit
    SIMPLE_CLI_APPLICATION

feature {NONE} -- Initialization

    make
        do
            Precursor
            register_command (create {INIT_COMMAND})
            register_command (create {CREATE_COMMAND})
            register_command (create {UP_COMMAND})
            register_command (create {DOWN_COMMAND})
            register_command (create {STATUS_COMMAND})
            register_command (create {DIFF_COMMAND})
            register_command (create {GENERATE_COMMAND})
        end

feature -- Access

    application_name: STRING = "data-migrator"
    application_version: STRING = "1.0.0"

end

class UP_COMMAND

inherit
    SIMPLE_CLI_COMMAND

feature -- Specification

    name: STRING = "up"
    description: STRING = "Run pending migrations"

    options: ARRAYED_LIST [SIMPLE_CLI_OPTION]
        once
            create Result.make (3)
            Result.extend (create {SIMPLE_CLI_OPTION}.make_required ("db", "Database file"))
            Result.extend (create {SIMPLE_CLI_OPTION}.make_optional ("steps", "Number of migrations to run"))
            Result.extend (create {SIMPLE_CLI_OPTION}.make_flag ("dry-run", "Show SQL without executing"))
        end

feature -- Execution

    execute (a_context: SIMPLE_CLI_CONTEXT)
        local
            l_runner: MIGRATOR_RUNNER
            l_db_path: STRING
            l_steps: INTEGER
        do
            l_db_path := a_context.required_option ("db")
            l_steps := a_context.integer_option ("steps", 0)  -- 0 = all

            create l_runner.make (l_db_path)

            if a_context.has_flag ("dry-run") then
                l_runner.dry_run_pending (l_steps)
                across l_runner.pending_sql as sql loop
                    io.put_string (sql)
                    io.put_new_line
                end
            else
                l_runner.run_pending (l_steps)
                if l_runner.has_error then
                    io.put_string ("Error: " + l_runner.last_error)
                    a_context.set_exit_code (4)
                else
                    io.put_string ("Applied " + l_runner.migrations_applied.out + " migration(s)")
                end
            end
        end

end
```

### simple_diff Integration (Optional)

**Purpose:** Text-based diff visualization for schema changes

**Usage:**
```eiffel
class SCHEMA_DIFF

feature -- Output

    to_diff_string: STRING
            -- Generate unified diff format output
        local
            l_diff: SIMPLE_DIFF
        do
            create l_diff.make

            create Result.make (1000)

            -- For each modified table, show column diff
            across modified_tables as t loop
                Result.append ("--- " + t.key + " (source)%N")
                Result.append ("+++ " + t.key + " (target)%N")

                if attached t.removed_columns as removed then
                    across removed as col loop
                        Result.append ("- " + col.description + "%N")
                    end
                end

                if attached t.added_columns as added then
                    across added as col loop
                        Result.append ("+ " + col.description + "%N")
                    end
                end
            end
        end

end
```

---

## Dependency Graph

```
data-migrator
    |
    +-- simple_sql (required)
    |       |
    |       +-- SIMPLE_SQL_DATABASE
    |       +-- SIMPLE_SQL_MIGRATION
    |       +-- SIMPLE_SQL_MIGRATION_RUNNER
    |       +-- SIMPLE_SQL_SCHEMA
    |       +-- SIMPLE_SQL_TABLE_INFO
    |       +-- SIMPLE_SQL_COLUMN_INFO
    |       +-- SIMPLE_SQL_EXPORT
    |       +-- SIMPLE_SQL_IMPORT
    |
    +-- simple_json (required)
    |       |
    |       +-- SIMPLE_JSON
    |       +-- SIMPLE_JSON_OBJECT
    |
    +-- simple_cli (required)
    |       |
    |       +-- SIMPLE_CLI_APPLICATION
    |       +-- SIMPLE_CLI_COMMAND
    |       +-- SIMPLE_CLI_OPTION
    |
    +-- simple_file (required)
    |       |
    |       +-- SIMPLE_FILE
    |       +-- SIMPLE_DIRECTORY
    |
    +-- simple_diff (optional)
    |       |
    |       +-- SIMPLE_DIFF
    |
    +-- simple_csv (optional)
    |       |
    |       +-- SIMPLE_CSV_READER
    |       +-- SIMPLE_CSV_WRITER
    |
    +-- simple_hash (optional)
    |       |
    |       +-- SIMPLE_MD5
    |
    +-- ISE base (required)
            |
            +-- ARRAYED_LIST
            +-- HASH_TABLE
            +-- PATH
```

---

## ECF Configuration

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<system xmlns="http://www.eiffel.com/developers/xml/configuration-1-23-0"
        name="data_migrator" uuid="DATA-MIGRATOR-UUID-HERE">

    <description>DATA-MIGRATOR: CLI Database Migration Toolkit for SQLite</description>

    <!-- Library target -->
    <target name="data_migrator">
        <root all_classes="true"/>
        <option warning="warning" syntax="standard">
            <assertions precondition="true" postcondition="true" check="true"/>
        </option>

        <cluster name="src" location=".\src\" recursive="true"/>

        <!-- Required simple_* libraries -->
        <library name="simple_sql" location="$SIMPLE_EIFFEL\simple_sql\simple_sql.ecf"/>
        <library name="simple_json" location="$SIMPLE_EIFFEL\simple_json\simple_json.ecf"/>
        <library name="simple_cli" location="$SIMPLE_EIFFEL\simple_cli\simple_cli.ecf"/>
        <library name="simple_file" location="$SIMPLE_EIFFEL\simple_file\simple_file.ecf"/>

        <!-- Optional simple_* libraries -->
        <library name="simple_diff" location="$SIMPLE_EIFFEL\simple_diff\simple_diff.ecf"/>
        <library name="simple_csv" location="$SIMPLE_EIFFEL\simple_csv\simple_csv.ecf"/>
        <library name="simple_hash" location="$SIMPLE_EIFFEL\simple_hash\simple_hash.ecf"/>
        <library name="simple_logger" location="$SIMPLE_EIFFEL\simple_logger\simple_logger.ecf"/>

        <!-- ISE libraries -->
        <library name="base" location="$ISE_LIBRARY\library\base\base.ecf"/>
        <library name="time" location="$ISE_LIBRARY\library\time\time.ecf"/>
    </target>

    <!-- CLI executable -->
    <target name="data_migrator_cli" extends="data_migrator">
        <root class="DATA_MIGRATOR_CLI" feature="make"/>
        <setting name="executable_name" value="data-migrator"/>
    </target>

    <!-- Test target -->
    <target name="data_migrator_tests" extends="data_migrator">
        <root class="TEST_APP" feature="make"/>
        <library name="simple_testing" location="$SIMPLE_EIFFEL\simple_testing\simple_testing.ecf"/>
        <cluster name="tests" location=".\tests\" recursive="true"/>
    </target>

</system>
```

---

## Integration Test Scenarios

### Scenario 1: Basic Migration Workflow
```bash
# Initialize
data-migrator init

# Create migration
data-migrator create create_users_table

# Edit migration file (add SQL)
# ./migrations/20260124000000_create_users_table.sql

# Run migration
data-migrator up --db app.db

# Check status
data-migrator status --db app.db
# Expected: create_users_table: applied
```

### Scenario 2: Schema Diff and Generate
```bash
# Compare dev and prod
data-migrator diff --db dev.db --target prod.db
# Expected: Shows differences

# Generate migration
data-migrator generate --db dev.db --target prod.db --name sync_prod

# Review generated SQL
cat ./migrations/20260124120000_sync_prod.sql

# Apply to prod (with confirmation)
data-migrator up --db prod.db
```

### Scenario 3: Rollback
```bash
# Check current status
data-migrator status --db app.db
# Version: 3

# Rollback 1 step
data-migrator down --db app.db

# Verify
data-migrator status --db app.db
# Version: 2
```

### Scenario 4: CI/CD Pipeline
```yaml
# .github/workflows/deploy.yml
- name: Run migrations
  run: |
    data-migrator up --db ${{ env.DB_PATH }} --output json
    if [ $? -ne 0 ]; then
      echo "Migration failed!"
      exit 1
    fi
```
