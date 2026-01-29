# DATA-MIGRATOR - Technical Design

---

## Architecture

### Component Overview

```
+-------------------------------------------------------------+
|                     DATA-MIGRATOR CLI                        |
+-------------------------------------------------------------+
|  CLI Interface Layer                                         |
|    - Argument parsing (simple_cli)                           |
|    - Command routing                                         |
|    - Output formatting (text/json)                           |
+-------------------------------------------------------------+
|  Business Logic Layer                                        |
|    - Migration runner (MIGRATOR_RUNNER)                      |
|    - Schema differ (MIGRATOR_DIFF)                           |
|    - ETL pipeline (MIGRATOR_ETL)                             |
+-------------------------------------------------------------+
|  Integration Layer                                           |
|    - simple_sql (migration, schema, export/import)           |
|    - simple_diff (text diffing)                              |
|    - simple_json (config, state)                             |
|    - simple_csv (data exchange)                              |
|    - simple_hash (checksum verification)                     |
+-------------------------------------------------------------+
|  Data Layer                                                  |
|    - Migration files (./migrations/*.sql)                    |
|    - Configuration (.data-migrator.json)                     |
|    - Target database                                         |
+-------------------------------------------------------------+
```

### Class Design

| Class | Responsibility | Key Features |
|-------|----------------|--------------|
| `DATA_MIGRATOR_CLI` | Command-line interface | parse_args, execute, format_output |
| `MIGRATOR_ENGINE` | Core orchestration | run_migrations, rollback, status |
| `MIGRATOR_RUNNER` | Execute migrations | up, down, to_version |
| `MIGRATOR_DIFF` | Schema comparison | diff_schemas, generate_migration |
| `MIGRATOR_ETL` | Data transformation | transform, export, import |
| `MIGRATOR_CONFIG` | Configuration management | load, save, profiles |
| `MIGRATION` | Migration entity | version, name, up_sql, down_sql |
| `SCHEMA_DIFF` | Diff result | added, removed, modified, sql |
| `ETL_PIPELINE` | Transform pipeline | source, transforms, target |

### Command Structure

```bash
data-migrator <command> [options] [arguments]

Commands:
  init        Initialize migration directory
  create      Create new migration file
  up          Run pending migrations
  down        Rollback migrations
  status      Show migration status
  diff        Compare two databases
  generate    Generate migration from diff
  export      Export data to file
  import      Import data from file
  seed        Run seed data files

Global Options:
  --db FILE        Target database file (required for most commands)
  --config FILE    Configuration file (default: .data-migrator.json)
  --env NAME       Environment profile (default: development)
  --output FORMAT  Output format: text, json (default: text)
  --dry-run        Show what would be done without doing it
  --verbose        Verbose output
  --quiet          Suppress non-essential output
  --help           Show help

Examples:
  data-migrator init
  data-migrator create add_users_table
  data-migrator up --db app.db
  data-migrator down --db app.db --steps 1
  data-migrator diff --db app.db --target prod.db
  data-migrator generate --db dev.db --target prod.db --name sync_schema
```

### Detailed Command Specifications

#### init command
```bash
data-migrator init [options]

Options:
  --directory DIR  Migration directory (default: ./migrations)
  --config FILE    Configuration file path

Creates:
  ./migrations/            Migration files directory
  .data-migrator.json      Configuration file

Examples:
  data-migrator init
  data-migrator init --directory ./db/migrations
```

#### create command
```bash
data-migrator create <name> [options]

Arguments:
  name              Migration name (will be prefixed with timestamp)

Options:
  --sql SQL         SQL for up migration (opens editor if not provided)
  --reversible      Include down migration template

Creates:
  ./migrations/20260124120000_<name>.sql

Examples:
  data-migrator create add_users_table
  data-migrator create add_email_column --reversible
  data-migrator create fix_constraint --sql "ALTER TABLE users ADD COLUMN email TEXT"
```

#### up command
```bash
data-migrator up --db <file> [options]

Options:
  --steps N         Run only N pending migrations
  --to VERSION      Migrate to specific version
  --dry-run         Show SQL without executing
  --force           Skip confirmation prompts

Examples:
  data-migrator up --db app.db                    # All pending
  data-migrator up --db app.db --steps 1          # Next migration only
  data-migrator up --db app.db --to 20260124      # Up to version
  data-migrator up --db app.db --dry-run          # Preview
```

#### down command
```bash
data-migrator down --db <file> [options]

Options:
  --steps N         Rollback N migrations (default: 1)
  --to VERSION      Rollback to specific version
  --all             Rollback all migrations
  --dry-run         Show SQL without executing
  --force           Skip confirmation prompts

Examples:
  data-migrator down --db app.db                  # Rollback 1
  data-migrator down --db app.db --steps 3        # Rollback 3
  data-migrator down --db app.db --to 20260101    # Rollback to version
  data-migrator down --db app.db --all --force    # Reset everything
```

#### status command
```bash
data-migrator status --db <file> [options]

Options:
  --pending         Show only pending migrations
  --applied         Show only applied migrations

Output:
  Version    Name                    Status      Applied At
  -------    ----                    ------      ----------
  20260101   create_users            applied     2026-01-01 10:00
  20260115   add_email_column        applied     2026-01-15 14:30
  20260124   add_orders_table        pending     -

Examples:
  data-migrator status --db app.db
  data-migrator status --db app.db --pending --output json
```

#### diff command
```bash
data-migrator diff --db <source> --target <target> [options]

Options:
  --tables LIST     Compare only specified tables
  --ignore-order    Ignore column order differences
  --data            Include data differences

Output:
  Tables added: orders, order_items
  Tables removed: (none)
  Tables modified:
    users:
      + column: email TEXT
      + index: idx_users_email
      - column: phone
      ~ column: name VARCHAR(100) -> VARCHAR(255)

Examples:
  data-migrator diff --db dev.db --target prod.db
  data-migrator diff --db dev.db --target prod.db --output json
```

#### generate command
```bash
data-migrator generate --db <source> --target <target> --name <name> [options]

Options:
  --reversible      Generate down migration
  --skip-data       Don't include data transformations

Creates:
  ./migrations/20260124120000_<name>.sql

Examples:
  data-migrator generate --db dev.db --target prod.db --name sync_schema
  data-migrator generate --db v1.db --target v2.db --name upgrade_v2 --reversible
```

### Data Flow

```
                    +------------------+
                    |  Migration Files |
                    | ./migrations/    |
                    +------------------+
                           |
                           v
+------------+      +------------------+      +------------------+
|  create    | ---> | MIGRATION entity | ---> | SQL file created |
|  command   |      | (parse template) |      +------------------+
+------------+      +------------------+

+------------+      +------------------+      +------------------+
|  up        | ---> | MIGRATOR_RUNNER  | ---> | Database updated |
|  command   |      | (execute SQL)    |      | user_version++   |
+------------+      +------------------+      +------------------+

+------------+      +------------------+      +------------------+
|  diff      | ---> | MIGRATOR_DIFF    | ---> | SCHEMA_DIFF      |
|  command   |      | (compare schemas)|      | (differences)    |
+------------+      +------------------+      +------------------+
                           |
                           v
+------------+      +------------------+      +------------------+
|  generate  | ---> | SCHEMA_DIFF      | ---> | Migration SQL    |
|  command   |      | (to_migration)   |      | file created     |
+------------+      +------------------+      +------------------+
```

### Configuration Schema

```json
{
  "data_migrator": {
    "version": "1.0",
    "migrations_directory": "./migrations",
    "environments": {
      "development": {
        "database": "./dev.db"
      },
      "test": {
        "database": ":memory:"
      },
      "staging": {
        "database": "/data/staging.db"
      },
      "production": {
        "database": "/data/prod.db",
        "require_confirmation": true
      }
    },
    "defaults": {
      "reversible": true,
      "checksum_verification": true,
      "backup_before_down": true
    },
    "naming": {
      "timestamp_format": "yyyymmddHHMMSS",
      "separator": "_"
    }
  }
}
```

### Migration File Format

```sql
-- Migration: 20260124120000_add_users_table
-- Created: 2026-01-24 12:00:00
-- Author: developer@example.com

-- +up
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);

-- +down
DROP INDEX IF EXISTS idx_users_email;
DROP TABLE IF EXISTS users;
```

### Error Handling

| Error Type | Handling | User Message |
|------------|----------|--------------|
| Database not found | Exit 1 | "Error: Database file not found: {path}" |
| Migration not found | Exit 1 | "Error: No migrations found in {directory}" |
| Migration failed | Rollback, Exit 1 | "Error: Migration failed at {version}: {error}" |
| Already at version | Warning | "Warning: Database already at version {version}" |
| Checksum mismatch | Exit 1 | "Error: Migration {version} has been modified since applied" |
| Down not available | Exit 1 | "Error: Migration {version} has no down migration" |
| Permission denied | Exit 1 | "Error: Cannot write to database (read-only)" |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Invalid arguments |
| 3 | Database error |
| 4 | Migration error |
| 5 | Checksum mismatch |
| 10 | Pending migrations (with --check flag) |

---

## GUI/TUI Future Path

**CLI foundation enables:**
- All migration logic in library classes (reusable)
- JSON output for programmatic consumption
- Configuration file for GUI to read/write

**What would change for TUI:**
- Add simple_tui dependency
- Interactive migration selection
- Real-time status display
- Schema diff visualization

**What would change for GUI:**
- Visual schema designer
- Drag-and-drop migration ordering
- Side-by-side diff view
- Timeline of applied migrations

**Shared components:**
- MIGRATOR_ENGINE (all business logic)
- MIGRATOR_RUNNER (migration execution)
- MIGRATOR_DIFF (schema comparison)
- All entity classes

---

## Migration Tracking Schema

```sql
-- Stored in target database (optional, for detailed tracking)
CREATE TABLE IF NOT EXISTS _data_migrator_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    version TEXT NOT NULL,
    name TEXT NOT NULL,
    applied_at TEXT NOT NULL,
    execution_time_ms INTEGER,
    checksum TEXT,
    applied_by TEXT
);

-- Note: Primary tracking uses PRAGMA user_version for simplicity
-- _data_migrator_history is optional for detailed auditing
```
