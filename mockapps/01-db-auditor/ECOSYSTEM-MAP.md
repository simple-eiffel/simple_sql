# DB-AUDITOR - Ecosystem Integration

---

## simple_* Dependencies

### Required Libraries

| Library | Purpose | Integration Point |
|---------|---------|-------------------|
| simple_sql | Core audit functionality, schema introspection, export | SIMPLE_SQL_AUDIT, SIMPLE_SQL_SCHEMA, SIMPLE_SQL_EXPORT |
| simple_json | Configuration files, report data, JSON output | Configuration parsing, report serialization |
| simple_cli | Command-line argument parsing, help generation | CLI interface, option handling |
| simple_datetime | Timestamp parsing, date range calculations | Query filters, report periods |

### Optional Libraries

| Library | Purpose | When Needed |
|---------|---------|-------------|
| simple_csv | CSV export format | When --output csv specified |
| simple_template | HTML report generation | When generating HTML reports |
| simple_hash | Integrity verification | Phase 3: audit trail hashing |
| simple_email | Alert notifications | Enterprise: email alerts |
| simple_http | Webhook notifications | When --webhook specified |

---

## Integration Patterns

### simple_sql Integration

**Purpose:** Core database operations, audit trail management, schema queries

**Usage:**
```eiffel
class AUDITOR_ENGINE

feature -- Audit Management

    enable_auditing (a_table: STRING)
            -- Enable audit trail for table
        local
            l_audit: SIMPLE_SQL_AUDIT
        do
            l_audit := database.audit
            l_audit.enable_for_table (a_table)
        ensure
            auditing_enabled: is_table_audited (a_table)
        end

    query_changes (a_table: STRING; a_since: DATE_TIME): ARRAYED_LIST [AUDIT_CHANGE]
            -- Get changes for table since date
        local
            l_audit: SIMPLE_SQL_AUDIT
            l_result: SIMPLE_SQL_RESULT
        do
            l_audit := database.audit
            l_result := l_audit.get_changes_in_range (a_table,
                a_since.formatted_out ("yyyy-mm-dd hh:mi:ss"),
                create {DATE_TIME}.make_now.formatted_out ("yyyy-mm-dd hh:mi:ss"))

            create Result.make (l_result.count)
            across l_result.rows as row loop
                Result.extend (create {AUDIT_CHANGE}.make_from_row (row))
            end
        end

feature -- Schema Queries

    auditable_tables: ARRAYED_LIST [STRING]
            -- Get all tables that can be audited
        local
            l_schema: SIMPLE_SQL_SCHEMA
        do
            l_schema := database.schema
            create Result.make_from_array (l_schema.tables.to_array)
            -- Exclude system tables
            Result.prune_all ("sqlite_sequence")
            Result.prune_all ("sqlite_stat1")
        end

end
```

**Data flow:**
```
CLI Command -> AUDITOR_ENGINE -> SIMPLE_SQL_AUDIT -> SQLite Triggers
                                SIMPLE_SQL_SCHEMA -> sqlite_master
                                SIMPLE_SQL_EXPORT -> CSV/JSON files
```

### simple_json Integration

**Purpose:** Configuration management, JSON output format, report data

**Usage:**
```eiffel
class AUDITOR_CONFIG

feature -- Configuration

    load_config (a_path: PATH)
            -- Load configuration from JSON file
        local
            l_json: SIMPLE_JSON
            l_file: PLAIN_TEXT_FILE
            l_content: STRING
        do
            create l_file.make_with_path (a_path)
            l_file.read_all
            l_content := l_file.last_string
            l_file.close

            create l_json.make
            if attached l_json.parse (l_content) as l_root then
                if attached l_root.as_object as l_obj then
                    parse_config_object (l_obj)
                end
            end
        end

    save_config (a_path: PATH)
            -- Save configuration to JSON file
        local
            l_json: SIMPLE_JSON_OBJECT
        do
            create l_json.make
            l_json.put_string (output_format, "output_format").do_nothing
            l_json.put_integer (retention_days, "retention_days").do_nothing
            -- ... more fields

            write_to_file (l_json.to_json_string, a_path)
        end

end
```

### simple_cli Integration

**Purpose:** Command-line interface, argument parsing, help generation

**Usage:**
```eiffel
class DB_AUDITOR_CLI

inherit
    SIMPLE_CLI_APPLICATION
        redefine
            application_name,
            application_version,
            make
        end

feature {NONE} -- Initialization

    make
        do
            Precursor
            register_command (create {AUDITOR_SETUP_COMMAND})
            register_command (create {AUDITOR_QUERY_COMMAND})
            register_command (create {AUDITOR_REPORT_COMMAND})
            register_command (create {AUDITOR_ANALYZE_COMMAND})
        end

feature -- Access

    application_name: STRING = "db-auditor"
    application_version: STRING = "1.0.0"

end

class AUDITOR_QUERY_COMMAND

inherit
    SIMPLE_CLI_COMMAND

feature -- Execution

    name: STRING = "query"
    description: STRING = "Query change history"

    execute (a_context: SIMPLE_CLI_CONTEXT)
        local
            l_engine: AUDITOR_ENGINE
            l_table: detachable STRING
            l_since: detachable DATE_TIME
        do
            l_table := a_context.option_value ("table")
            l_since := parse_datetime (a_context.option_value ("since"))

            create l_engine.make (a_context.required_option ("db"))
            across l_engine.query_changes (l_table, l_since) as change loop
                output_change (change, a_context.option_value ("output"))
            end
        end

end
```

### simple_datetime Integration

**Purpose:** Timestamp parsing, date arithmetic, period calculations

**Usage:**
```eiffel
class AUDITOR_QUERY

feature -- Date Filtering

    changes_since (a_since: STRING): ARRAYED_LIST [AUDIT_CHANGE]
            -- Get changes since ISO 8601 date string
        local
            l_datetime: SIMPLE_DATETIME
            l_since_dt: DATE_TIME
        do
            create l_datetime.make_from_iso8601 (a_since)
            l_since_dt := l_datetime.to_date_time

            Result := query_changes_after (l_since_dt)
        end

    changes_in_period (a_period: STRING): ARRAYED_LIST [AUDIT_CHANGE]
            -- Get changes for named period (today, week, month, quarter, year)
        local
            l_now: SIMPLE_DATETIME
            l_start, l_end: DATE_TIME
        do
            create l_now.make_now

            inspect a_period
            when "today" then
                l_start := l_now.start_of_day
                l_end := l_now.to_date_time
            when "week" then
                l_start := l_now.start_of_week
                l_end := l_now.to_date_time
            when "month" then
                l_start := l_now.start_of_month
                l_end := l_now.to_date_time
            when "quarter" then
                l_start := l_now.start_of_quarter
                l_end := l_now.to_date_time
            when "year" then
                l_start := l_now.start_of_year
                l_end := l_now.to_date_time
            end

            Result := query_changes_between (l_start, l_end)
        end

end
```

### simple_template Integration (Optional)

**Purpose:** HTML report generation with templates

**Usage:**
```eiffel
class AUDITOR_REPORTER

feature -- HTML Reports

    generate_html_report (a_template: STRING; a_data: AUDIT_REPORT): STRING
            -- Generate HTML report from template
        local
            l_engine: SIMPLE_TEMPLATE_ENGINE
            l_context: SIMPLE_TEMPLATE_CONTEXT
        do
            create l_engine.make
            create l_context.make

            l_context.put (a_data.title, "title")
            l_context.put (a_data.generated_at.out, "generated_at")
            l_context.put (a_data.period_description, "period")
            l_context.put_list (a_data.sections, "sections")
            l_context.put (a_data.summary, "summary")

            Result := l_engine.render (load_template (a_template), l_context)
        end

end
```

---

## Dependency Graph

```
db-auditor
    |
    +-- simple_sql (required)
    |       |
    |       +-- SIMPLE_SQL_DATABASE
    |       +-- SIMPLE_SQL_AUDIT
    |       +-- SIMPLE_SQL_SCHEMA
    |       +-- SIMPLE_SQL_EXPORT
    |       +-- SIMPLE_SQL_RESULT
    |       +-- SIMPLE_SQL_ROW
    |
    +-- simple_json (required)
    |       |
    |       +-- SIMPLE_JSON
    |       +-- SIMPLE_JSON_OBJECT
    |       +-- SIMPLE_JSON_ARRAY
    |
    +-- simple_cli (required)
    |       |
    |       +-- SIMPLE_CLI_APPLICATION
    |       +-- SIMPLE_CLI_COMMAND
    |       +-- SIMPLE_CLI_CONTEXT
    |
    +-- simple_datetime (required)
    |       |
    |       +-- SIMPLE_DATETIME
    |       +-- SIMPLE_DATE_RANGE
    |
    +-- simple_csv (optional)
    |       |
    |       +-- SIMPLE_CSV_WRITER
    |
    +-- simple_template (optional)
    |       |
    |       +-- SIMPLE_TEMPLATE_ENGINE
    |
    +-- simple_hash (optional, Phase 3)
    |       |
    |       +-- SIMPLE_SHA256
    |
    +-- ISE base (required)
            |
            +-- ARRAYED_LIST
            +-- HASH_TABLE
            +-- DATE_TIME
```

---

## ECF Configuration

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<system xmlns="http://www.eiffel.com/developers/xml/configuration-1-23-0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.eiffel.com/developers/xml/configuration-1-23-0
        http://www.eiffel.com/developers/xml/configuration-1-23-0.xsd"
        name="db_auditor" uuid="DB-AUDITOR-UUID-HERE">

    <description>DB-AUDITOR: Enterprise Database Audit Trail Generator</description>

    <!-- Library target (reusable) -->
    <target name="db_auditor">
        <root all_classes="true"/>
        <file_rule>
            <exclude>/EIFGENs$</exclude>
            <exclude>/\.git$</exclude>
        </file_rule>
        <option warning="warning" syntax="standard" manifest_array_type="mismatch_warning">
            <assertions precondition="true" postcondition="true" check="true" invariant="true"/>
        </option>

        <!-- Source clusters -->
        <cluster name="src" location=".\src\" recursive="true"/>

        <!-- simple_* dependencies (required) -->
        <library name="simple_sql" location="$SIMPLE_EIFFEL\simple_sql\simple_sql.ecf"/>
        <library name="simple_json" location="$SIMPLE_EIFFEL\simple_json\simple_json.ecf"/>
        <library name="simple_cli" location="$SIMPLE_EIFFEL\simple_cli\simple_cli.ecf"/>
        <library name="simple_datetime" location="$SIMPLE_EIFFEL\simple_datetime\simple_datetime.ecf"/>

        <!-- simple_* dependencies (optional) -->
        <library name="simple_csv" location="$SIMPLE_EIFFEL\simple_csv\simple_csv.ecf"/>
        <library name="simple_template" location="$SIMPLE_EIFFEL\simple_template\simple_template.ecf"/>

        <!-- ISE libraries -->
        <library name="base" location="$ISE_LIBRARY\library\base\base.ecf"/>
        <library name="time" location="$ISE_LIBRARY\library\time\time.ecf"/>
    </target>

    <!-- CLI executable target -->
    <target name="db_auditor_cli" extends="db_auditor">
        <root class="DB_AUDITOR_CLI" feature="make"/>
        <setting name="executable_name" value="db-auditor"/>
        <capability>
            <concurrency use="none"/>
        </capability>
    </target>

    <!-- Test target -->
    <target name="db_auditor_tests" extends="db_auditor">
        <root class="TEST_APP" feature="make"/>
        <library name="simple_testing" location="$SIMPLE_EIFFEL\simple_testing\simple_testing.ecf"/>
        <cluster name="tests" location=".\tests\" recursive="true"/>
    </target>

</system>
```

---

## Integration Test Scenarios

### Scenario 1: Enable Auditing
```bash
# Setup
db-auditor setup --db test.db enable users orders

# Verify
db-auditor setup --db test.db status
# Expected: users: ENABLED, orders: ENABLED
```

### Scenario 2: Query Changes
```bash
# Make changes to database
sqlite3 test.db "INSERT INTO users (name) VALUES ('Alice')"
sqlite3 test.db "UPDATE users SET name = 'Bob' WHERE name = 'Alice'"

# Query
db-auditor query --db test.db --table users --output json
# Expected: JSON array with INSERT and UPDATE records
```

### Scenario 3: Generate Report
```bash
# Generate SOX compliance report
db-auditor report --db test.db --template sox --period month --output report.html

# Verify report contains required sections
grep "Change Summary" report.html
grep "Data Modifications" report.html
```

### Scenario 4: Anomaly Detection
```bash
# Create bulk delete scenario
sqlite3 test.db "DELETE FROM orders WHERE status = 'completed'"

# Analyze
db-auditor analyze --db test.db --detect bulk-deletes --threshold 10 --alert
# Expected: Exit code 10 if >10 deletes detected
```
