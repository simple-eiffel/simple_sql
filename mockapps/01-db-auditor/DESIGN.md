# DB-AUDITOR - Technical Design

---

## Architecture

### Component Overview

```
+-------------------------------------------------------------+
|                       DB-AUDITOR CLI                         |
+-------------------------------------------------------------+
|  CLI Interface Layer                                         |
|    - Argument parsing (simple_cli)                           |
|    - Command routing                                         |
|    - Output formatting (text/json/csv)                       |
+-------------------------------------------------------------+
|  Business Logic Layer                                        |
|    - Audit enablement (AUDITOR_SETUP)                        |
|    - Change queries (AUDITOR_QUERY)                          |
|    - Report generation (AUDITOR_REPORTER)                    |
|    - Anomaly detection (AUDITOR_ANALYZER)                    |
+-------------------------------------------------------------+
|  Integration Layer                                           |
|    - simple_sql (audit, schema, export)                      |
|    - simple_json (report serialization)                      |
|    - simple_csv (data export)                                |
|    - simple_datetime (timestamp handling)                    |
|    - simple_template (report rendering)                      |
+-------------------------------------------------------------+
|  Data Layer                                                  |
|    - Target SQLite database                                  |
|    - Audit tables (_audit_*)                                 |
|    - Configuration table (_auditor_config)                   |
+-------------------------------------------------------------+
```

### Class Design

| Class | Responsibility | Key Features |
|-------|----------------|--------------|
| `DB_AUDITOR_CLI` | Command-line interface | parse_args, execute, format_output |
| `AUDITOR_ENGINE` | Core orchestration | enable_audit, query_changes, generate_report |
| `AUDITOR_SETUP` | Audit configuration | enable_table, disable_table, list_audited |
| `AUDITOR_QUERY` | Change history queries | by_table, by_record, by_time_range, by_user |
| `AUDITOR_REPORTER` | Report generation | compliance_report, summary_report, custom_report |
| `AUDITOR_ANALYZER` | Anomaly detection | bulk_changes, off_hours, pattern_matching |
| `AUDITOR_CONFIG` | Configuration management | load, save, validate, profiles |
| `AUDIT_CHANGE` | Change record entity | table, record_id, operation, old_values, new_values |
| `AUDIT_REPORT` | Report entity | title, sections, data, format |
| `COMPLIANCE_TEMPLATE` | Report template | SOX, HIPAA, PCI_DSS, GDPR |

### Command Structure

```bash
db-auditor <command> [options] [arguments]

Commands:
  setup       Enable/disable auditing on tables
  query       Query change history
  report      Generate compliance reports
  analyze     Detect anomalies in change patterns
  export      Export audit data
  config      Manage configuration
  verify      Verify audit trail integrity

Global Options:
  --db FILE        Target database file (required)
  --config FILE    Configuration file (default: .db-auditor.json)
  --output FORMAT  Output format: text, json, csv, html (default: text)
  --verbose        Verbose output
  --quiet          Suppress non-essential output
  --help           Show help

Examples:
  db-auditor setup --db app.db enable users orders
  db-auditor query --db app.db --table users --since "2026-01-01"
  db-auditor report --db app.db --template sox --output report.html
  db-auditor analyze --db app.db --detect bulk-deletes
```

### Detailed Command Specifications

#### setup command
```bash
db-auditor setup --db <file> <action> [tables...]

Actions:
  enable [tables]   Enable auditing (all tables if none specified)
  disable [tables]  Disable auditing
  status            Show auditing status for all tables
  reset             Remove all audit data (with confirmation)

Options:
  --include-system  Include SQLite system tables
  --retention DAYS  Set audit data retention (default: 365)

Examples:
  db-auditor setup --db app.db enable                    # All tables
  db-auditor setup --db app.db enable users orders       # Specific tables
  db-auditor setup --db app.db disable orders            # Disable one
  db-auditor setup --db app.db status                    # Check status
  db-auditor setup --db app.db reset --confirm           # Clear audit data
```

#### query command
```bash
db-auditor query --db <file> [filters...]

Filters:
  --table NAME      Filter by table name
  --record ID       Filter by record ID
  --operation TYPE  Filter: INSERT, UPDATE, DELETE
  --since DATE      Changes since date (ISO 8601)
  --until DATE      Changes until date
  --user NAME       Filter by user (if tracked)
  --field NAME      Filter by changed field name

Output Options:
  --limit N         Maximum records (default: 100)
  --offset N        Skip first N records
  --sort FIELD      Sort by: timestamp, table, operation
  --desc            Descending order

Examples:
  db-auditor query --db app.db --table users --since "2026-01-01"
  db-auditor query --db app.db --record 42 --table orders
  db-auditor query --db app.db --operation DELETE --limit 50
  db-auditor query --db app.db --field email --output json
```

#### report command
```bash
db-auditor report --db <file> --template <name> [options]

Templates:
  sox         SOX Sarbanes-Oxley compliance report
  hipaa       HIPAA audit trail report
  pci-dss     PCI-DSS data access report
  gdpr        GDPR data processing report
  summary     Daily/weekly change summary
  custom      Custom template from file

Options:
  --period RANGE    Time period: today, week, month, quarter, year, custom
  --since DATE      Custom period start
  --until DATE      Custom period end
  --tables LIST     Comma-separated table list
  --output FILE     Output file (stdout if not specified)
  --title TEXT      Report title
  --include-raw     Include raw change data

Examples:
  db-auditor report --db app.db --template sox --period quarter
  db-auditor report --db app.db --template gdpr --tables users,orders
  db-auditor report --db app.db --template custom --file my-template.html
```

#### analyze command
```bash
db-auditor analyze --db <file> --detect <pattern> [options]

Patterns:
  bulk-deletes      Large DELETE operations (>100 rows)
  bulk-updates      Large UPDATE operations
  off-hours         Changes outside business hours
  frequency         Unusual change frequency
  field-access      Specific field modifications
  all               Run all detection patterns

Options:
  --threshold N     Alert threshold (pattern-specific)
  --hours RANGE     Business hours (default: 09:00-17:00)
  --days LIST       Business days (default: Mon-Fri)
  --alert           Exit with error code if anomalies found
  --webhook URL     POST alerts to URL

Examples:
  db-auditor analyze --db app.db --detect bulk-deletes --threshold 50
  db-auditor analyze --db app.db --detect off-hours --hours "08:00-18:00"
  db-auditor analyze --db app.db --detect all --alert
```

### Data Flow

```
                    +-----------------+
                    |  Target SQLite  |
                    |    Database     |
                    +-----------------+
                           |
                           v
+------------+      +-----------------+      +------------------+
|  setup     | ---> |  SIMPLE_SQL     | ---> | _audit_* tables  |
|  command   |      |  AUDIT module   |      | (trigger-based)  |
+------------+      +-----------------+      +------------------+
                           |
                           v
+------------+      +-----------------+      +------------------+
|  query     | ---> |  AUDITOR_QUERY  | ---> | AUDIT_CHANGE[]   |
|  command   |      |  (SQL queries)  |      | (entity list)    |
+------------+      +-----------------+      +------------------+
                           |
                           v
+------------+      +-----------------+      +------------------+
|  report    | ---> | AUDITOR_REPORTER| ---> | HTML/JSON/CSV    |
|  command   |      | (templating)    |      | (output file)    |
+------------+      +-----------------+      +------------------+
                           |
                           v
+------------+      +-----------------+      +------------------+
|  analyze   | ---> | AUDITOR_ANALYZER| ---> | ANOMALY[]        |
|  command   |      | (pattern match) |      | (alerts)         |
+------------+      +-----------------+      +------------------+
```

### Configuration Schema

```json
{
  "db_auditor": {
    "version": "1.0",
    "defaults": {
      "output_format": "text",
      "retention_days": 365,
      "business_hours": {
        "start": "09:00",
        "end": "17:00",
        "days": ["Mon", "Tue", "Wed", "Thu", "Fri"]
      }
    },
    "auditing": {
      "enabled_tables": ["users", "orders", "payments"],
      "excluded_fields": ["password_hash", "session_token"],
      "track_user": true,
      "user_field": "modified_by"
    },
    "anomaly_detection": {
      "bulk_threshold": 100,
      "frequency_threshold": 10,
      "alert_webhook": null
    },
    "reporting": {
      "company_name": "Acme Corp",
      "compliance_officer": "Jane Smith",
      "default_template": "summary"
    }
  }
}
```

### Error Handling

| Error Type | Handling | User Message |
|------------|----------|--------------|
| Database not found | Exit 1 | "Error: Database file not found: {path}" |
| Table not found | Warning | "Warning: Table '{name}' does not exist" |
| Permission denied | Exit 1 | "Error: Cannot write to database (read-only)" |
| Audit not enabled | Exit 1 | "Error: Auditing not enabled. Run 'setup enable' first" |
| Invalid date format | Exit 1 | "Error: Invalid date format. Use ISO 8601 (YYYY-MM-DD)" |
| Template not found | Exit 1 | "Error: Template '{name}' not found" |
| Query timeout | Warning | "Warning: Query exceeded timeout, results truncated" |
| Integrity violation | Alert | "ALERT: Audit trail integrity check failed for {table}" |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Invalid arguments |
| 3 | Database error |
| 4 | Configuration error |
| 10 | Anomalies detected (with --alert flag) |
| 11 | Integrity check failed |

---

## GUI/TUI Future Path

**CLI foundation enables:**
- All business logic in library classes (reusable)
- JSON output format for API consumption
- Configuration file for GUI to read/write
- Report templates can be rendered in GUI

**What would change for TUI:**
- Add simple_tui dependency
- Create AUDITOR_TUI_APP class
- Interactive table selection
- Real-time change monitoring view
- Dashboard with charts

**What would change for GUI:**
- Add simple_gui or web interface
- Timeline visualization of changes
- Diff view for UPDATE operations
- Anomaly highlighting
- Report preview/export

**Shared components between CLI/GUI:**
- AUDITOR_ENGINE (all business logic)
- AUDITOR_QUERY (query building)
- AUDITOR_REPORTER (report generation)
- AUDITOR_ANALYZER (anomaly detection)
- All entity classes (AUDIT_CHANGE, etc.)

---

## Database Schema

### Audit Tables (created by simple_sql audit)

```sql
-- Per-table audit tables (created automatically)
CREATE TABLE _audit_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    operation TEXT NOT NULL,        -- INSERT, UPDATE, DELETE
    record_id INTEGER,              -- Primary key of affected record
    timestamp TEXT NOT NULL,        -- ISO 8601 timestamp
    old_values TEXT,                -- JSON of old values (UPDATE, DELETE)
    new_values TEXT                 -- JSON of new values (INSERT, UPDATE)
);

-- DB-AUDITOR configuration table
CREATE TABLE _auditor_config (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Integrity verification (Phase 3)
CREATE TABLE _auditor_integrity (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    table_name TEXT NOT NULL,
    record_count INTEGER NOT NULL,
    hash_chain TEXT NOT NULL,
    verified_at TEXT NOT NULL
);
```

### Compliance Report Schema

```
COMPLIANCE_REPORT
  - report_id: STRING (UUID)
  - template: STRING (sox/hipaa/pci-dss/gdpr)
  - generated_at: DATETIME
  - period_start: DATETIME
  - period_end: DATETIME
  - database_path: STRING
  - sections: LIST[REPORT_SECTION]
  - summary: REPORT_SUMMARY

REPORT_SECTION
  - title: STRING
  - description: STRING
  - data: LIST[AUDIT_CHANGE]
  - statistics: SECTION_STATS

SECTION_STATS
  - total_changes: INTEGER
  - inserts: INTEGER
  - updates: INTEGER
  - deletes: INTEGER
  - unique_records: INTEGER
  - unique_users: INTEGER
```
