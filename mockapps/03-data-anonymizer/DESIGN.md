# DATA-ANONYMIZER - Technical Design

---

## Architecture

### Component Overview

```
+-------------------------------------------------------------+
|                    DATA-ANONYMIZER CLI                       |
+-------------------------------------------------------------+
|  CLI Interface Layer                                         |
|    - Argument parsing (simple_cli)                           |
|    - Command routing                                         |
|    - Progress reporting                                      |
+-------------------------------------------------------------+
|  Business Logic Layer                                        |
|    - PII detection (ANONYMIZER_SCANNER)                      |
|    - Rule engine (ANONYMIZER_RULES)                          |
|    - Transform engine (ANONYMIZER_TRANSFORM)                 |
|    - Verification (ANONYMIZER_VERIFY)                        |
+-------------------------------------------------------------+
|  Strategy Layer                                              |
|    - Hash strategy (SHA-256)                                 |
|    - Fake strategy (realistic fake data)                     |
|    - Mask strategy (partial reveal)                          |
|    - Encrypt strategy (AES reversible)                       |
|    - Shuffle strategy (distribution preservation)            |
+-------------------------------------------------------------+
|  Integration Layer                                           |
|    - simple_sql (streaming, repository, soft delete)         |
|    - simple_json (rules configuration)                       |
|    - simple_hash (hashing)                                   |
|    - simple_encryption (AES for reversible)                  |
|    - simple_randomizer (fake data generation)                |
+-------------------------------------------------------------+
```

### Class Design

| Class | Responsibility | Key Features |
|-------|----------------|--------------|
| `DATA_ANONYMIZER_CLI` | Command-line interface | parse_args, execute, progress |
| `ANONYMIZER_ENGINE` | Core orchestration | scan, anonymize, verify |
| `ANONYMIZER_SCANNER` | PII detection | detect_patterns, classify_fields |
| `ANONYMIZER_RULES` | Rule management | load_rules, validate, apply |
| `ANONYMIZER_TRANSFORM` | Data transformation | process_table, process_row |
| `ANONYMIZER_VERIFY` | Result verification | verify_anonymized, check_integrity |
| `ANONYMIZATION_RULE` | Single rule entity | column, strategy, options |
| `ANONYMIZATION_STRATEGY` | Strategy interface | transform, is_reversible |
| `HASH_STRATEGY` | SHA-256 hashing | Inherits ANONYMIZATION_STRATEGY |
| `FAKE_STRATEGY` | Fake data generation | Inherits ANONYMIZATION_STRATEGY |
| `MASK_STRATEGY` | Partial masking | Inherits ANONYMIZATION_STRATEGY |
| `ENCRYPT_STRATEGY` | AES encryption | Inherits ANONYMIZATION_STRATEGY |

### Command Structure

```bash
data-anonymizer <command> [options] [arguments]

Commands:
  scan        Detect PII in database
  rules       Manage anonymization rules
  anonymize   Apply anonymization rules
  verify      Verify anonymization completeness
  reverse     Reverse reversible transformations
  audit       Generate audit report

Global Options:
  --db FILE        Source database file (required)
  --output FILE    Output database (default: <db>_anonymized.db)
  --config FILE    Rules configuration file
  --key FILE       Encryption key file (for reversible ops)
  --verbose        Verbose output
  --quiet          Suppress progress output
  --help           Show help

Examples:
  data-anonymizer scan --db customers.db
  data-anonymizer anonymize --db prod.db --config rules.json --output test.db
  data-anonymizer verify --db test.db --config rules.json
  data-anonymizer reverse --db test.db --key secret.key
```

### Detailed Command Specifications

#### scan command
```bash
data-anonymizer scan --db <file> [options]

Options:
  --tables LIST     Scan only specified tables
  --patterns FILE   Custom PII pattern definitions
  --threshold N     Detection confidence threshold (default: 0.8)
  --output FORMAT   Output: text, json (default: text)

Detects:
  - Email addresses (PATTERN_EMAIL)
  - Phone numbers (PATTERN_PHONE)
  - SSN/National IDs (PATTERN_SSN)
  - Credit card numbers (PATTERN_CREDIT_CARD)
  - IP addresses (PATTERN_IP)
  - Names (via column naming conventions)
  - Addresses (via column naming conventions)

Output:
  Table: users
    email       EMAIL       HIGH confidence
    phone       PHONE       HIGH confidence
    first_name  NAME        MEDIUM confidence (column name)
    ssn         SSN         HIGH confidence

Examples:
  data-anonymizer scan --db customers.db
  data-anonymizer scan --db customers.db --output json > pii-report.json
```

#### rules command
```bash
data-anonymizer rules <action> [options]

Actions:
  generate    Generate rules from scan results
  validate    Validate rules file
  show        Display current rules
  add         Add rule interactively

Options:
  --input FILE      Input rules file
  --output FILE     Output rules file
  --template NAME   Use predefined template (gdpr, hipaa, pci)

Examples:
  data-anonymizer rules generate --db customers.db --output rules.json
  data-anonymizer rules validate --input rules.json
  data-anonymizer rules show --input rules.json
```

#### anonymize command
```bash
data-anonymizer anonymize --db <source> --config <rules> [options]

Options:
  --output FILE     Output database (default: <db>_anonymized.db)
  --key FILE        Encryption key for reversible strategies
  --tables LIST     Process only specified tables
  --dry-run         Show what would be changed
  --preserve-fk     Maintain foreign key relationships
  --batch-size N    Records per batch (default: 1000)
  --progress        Show progress bar

Examples:
  data-anonymizer anonymize --db prod.db --config rules.json --output test.db
  data-anonymizer anonymize --db prod.db --config rules.json --dry-run
  data-anonymizer anonymize --db prod.db --config rules.json --key secret.key
```

#### verify command
```bash
data-anonymizer verify --db <file> --config <rules> [options]

Verifies:
  - All PII fields have been transformed
  - No original values remain
  - Foreign key integrity maintained
  - Data types preserved
  - Statistical distribution preserved (optional)

Options:
  --strict          Fail on any warning
  --sample N        Verify N random records per table

Output:
  Verification Report
  -------------------
  Table: users
    email: PASS (all transformed)
    phone: PASS (all transformed)
    ssn: PASS (all transformed)

  Table: orders
    FK integrity: PASS

  Overall: PASS (0 failures, 0 warnings)

Examples:
  data-anonymizer verify --db test.db --config rules.json
  data-anonymizer verify --db test.db --config rules.json --strict
```

#### reverse command
```bash
data-anonymizer reverse --db <file> --key <keyfile> [options]

Options:
  --tables LIST     Reverse only specified tables
  --columns LIST    Reverse only specified columns
  --output FILE     Output to new file (default: in-place)

Note: Only works for reversible strategies (encrypt, tokenize)

Examples:
  data-anonymizer reverse --db dev.db --key secret.key
  data-anonymizer reverse --db dev.db --key secret.key --tables users
```

### Rules Configuration Schema

```json
{
  "data_anonymizer": {
    "version": "1.0",
    "description": "Customer data anonymization rules",
    "tables": {
      "users": {
        "columns": {
          "email": {
            "strategy": "fake",
            "type": "email",
            "preserve_domain": false
          },
          "phone": {
            "strategy": "mask",
            "pattern": "***-***-####"
          },
          "ssn": {
            "strategy": "hash",
            "salt": "${SALT_ENV_VAR}"
          },
          "first_name": {
            "strategy": "fake",
            "type": "first_name",
            "preserve_gender": true
          },
          "last_name": {
            "strategy": "fake",
            "type": "last_name"
          },
          "address": {
            "strategy": "fake",
            "type": "address"
          },
          "credit_card": {
            "strategy": "replace",
            "value": "XXXX-XXXX-XXXX-XXXX"
          },
          "password_hash": {
            "strategy": "skip",
            "reason": "Already hashed"
          }
        },
        "preserve_pk": true,
        "preserve_fk": ["orders.user_id", "addresses.user_id"]
      },
      "orders": {
        "columns": {
          "shipping_address": {
            "strategy": "fake",
            "type": "address"
          }
        }
      }
    },
    "global_options": {
      "preserve_nulls": true,
      "deterministic": true,
      "seed": 12345
    }
  }
}
```

### Data Flow

```
+----------------+     +------------------+     +------------------+
|  Source DB     | --> | ANONYMIZER_SCAN  | --> | PII Report       |
|  (prod.db)     |     | (detect PII)     |     | (scan result)    |
+----------------+     +------------------+     +------------------+
                                                       |
                                                       v
+----------------+     +------------------+     +------------------+
|  Rules File    | --> | ANONYMIZER_RULES | --> | Validated Rules  |
|  (rules.json)  |     | (parse/validate) |     +------------------+
+----------------+     +------------------+            |
                                                       v
+----------------+     +---------------------+    +------------------+
|  Source DB     | --> | ANONYMIZER_TRANSFORM| --> | Anonymized DB   |
|  (prod.db)     |     | (streaming process) |    | (test.db)        |
+----------------+     +---------------------+    +------------------+
                              |                        |
                              v                        v
                       +-------------+          +------------------+
                       | Audit Trail |          | ANONYMIZER_VERIFY|
                       | (_audit_*)  |          | (check results)  |
                       +-------------+          +------------------+
```

### Strategy Implementation

```eiffel
deferred class ANONYMIZATION_STRATEGY

feature -- Access

    name: STRING
            -- Strategy name for configuration
        deferred
        end

    is_reversible: BOOLEAN
            -- Can transformation be reversed?
        deferred
        end

feature -- Transformation

    transform (a_value: detachable ANY; a_options: ANONYMIZATION_OPTIONS): detachable ANY
            -- Transform value according to strategy
        deferred
        end

    reverse (a_value: detachable ANY; a_options: ANONYMIZATION_OPTIONS): detachable ANY
            -- Reverse transformation (if reversible)
        require
            is_reversible: is_reversible
        deferred
        end

end

class FAKE_STRATEGY

inherit
    ANONYMIZATION_STRATEGY

feature -- Access

    name: STRING = "fake"
    is_reversible: BOOLEAN = False

feature -- Transformation

    transform (a_value: detachable ANY; a_options: ANONYMIZATION_OPTIONS): detachable ANY
        local
            l_faker: SIMPLE_RANDOMIZER
        do
            if a_value = Void then
                Result := Void  -- Preserve NULLs
            else
                create l_faker.make_with_seed (a_options.seed)

                inspect a_options.fake_type
                when "email" then
                    Result := l_faker.email
                when "first_name" then
                    Result := l_faker.first_name (a_options.preserve_gender)
                when "last_name" then
                    Result := l_faker.last_name
                when "phone" then
                    Result := l_faker.phone_number
                when "address" then
                    Result := l_faker.street_address
                when "city" then
                    Result := l_faker.city
                when "ssn" then
                    Result := l_faker.ssn
                else
                    Result := l_faker.random_string (a_value.out.count)
                end
            end
        end

end
```

### Error Handling

| Error Type | Handling | User Message |
|------------|----------|--------------|
| Database not found | Exit 1 | "Error: Database file not found: {path}" |
| Invalid rules | Exit 1 | "Error: Invalid rule at {path}: {reason}" |
| Strategy not found | Exit 1 | "Error: Unknown strategy: {name}" |
| Key file missing | Exit 1 | "Error: Encryption key file required for reversible strategies" |
| FK violation | Warning | "Warning: FK integrity may be affected for {table}.{column}" |
| Null in non-null | Warning | "Warning: Cannot apply strategy to NULL value in {column}" |
| Verification failed | Exit 2 | "Error: Verification failed: {details}" |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Verification failed |
| 3 | Database error |
| 4 | Configuration error |
| 10 | PII detected (with --check flag in CI) |

---

## GUI/TUI Future Path

**CLI foundation enables:**
- All transformation logic in library classes
- JSON rules readable/writable by GUI
- Progress callbacks for UI updates
- Audit data queryable for dashboards

**What would change for TUI:**
- Interactive rule builder
- Real-time progress display
- Data preview (before/after)
- Column selection interface

**What would change for GUI:**
- Visual rule designer
- Data sample preview
- Risk score visualization
- Compliance dashboard

**Shared components:**
- ANONYMIZER_ENGINE
- All strategy classes
- ANONYMIZER_RULES
- ANONYMIZER_VERIFY
