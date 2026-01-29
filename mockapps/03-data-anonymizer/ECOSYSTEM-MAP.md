# DATA-ANONYMIZER - Ecosystem Integration

---

## simple_* Dependencies

### Required Libraries

| Library | Purpose | Integration Point |
|---------|---------|-------------------|
| simple_sql | Streaming queries, repository pattern, soft delete | SIMPLE_SQL_CURSOR, SIMPLE_SQL_REPOSITORY |
| simple_json | Rules configuration, audit export | Rule parsing, JSON output |
| simple_cli | Command-line interface | CLI framework |
| simple_hash | One-way hashing (SHA-256) | Hash strategy |
| simple_randomizer | Fake data generation | Fake strategy |

### Optional Libraries

| Library | Purpose | When Needed |
|---------|---------|-------------|
| simple_encryption | AES encryption | Reversible encrypt strategy |
| simple_csv | Data export | Export anonymized data |
| simple_regex | PII pattern matching | Custom pattern detection |
| simple_validation | Rule validation | Complex rule validation |
| simple_logger | Detailed logging | Debug mode |

---

## Integration Patterns

### simple_sql Streaming Integration

**Purpose:** Memory-efficient processing of large databases

**Usage:**
```eiffel
class ANONYMIZER_TRANSFORM

feature -- Transformation

    process_table (a_table: STRING; a_rules: ARRAYED_LIST [ANONYMIZATION_RULE])
            -- Process all rows in table using streaming
        local
            l_cursor: SIMPLE_SQL_CURSOR
            l_row: SIMPLE_SQL_ROW
            l_new_values: HASH_TABLE [detachable ANY, STRING]
            l_update_builder: SIMPLE_SQL_UPDATE_BUILDER
        do
            -- Use cursor for memory-efficient iteration
            l_cursor := source_db.query_cursor ("SELECT * FROM " + a_table)

            from l_cursor.start
            until l_cursor.after
            loop
                l_row := l_cursor.item

                -- Transform row according to rules
                l_new_values := transform_row (l_row, a_rules)

                -- Write to target database
                write_transformed_row (a_table, l_row, l_new_values)

                -- Record in audit trail
                record_transformation (a_table, l_row, l_new_values)

                processed_count := processed_count + 1
                l_cursor.forth
            end

            l_cursor.close
        end

feature {NONE} -- Implementation

    transform_row (a_row: SIMPLE_SQL_ROW; a_rules: ARRAYED_LIST [ANONYMIZATION_RULE]):
            HASH_TABLE [detachable ANY, STRING]
            -- Apply rules to transform row values
        local
            l_strategy: ANONYMIZATION_STRATEGY
        do
            create Result.make (a_rules.count)

            across a_rules as rule loop
                l_strategy := strategy_for (rule.strategy_name)

                if attached a_row.item_by_name (rule.column) as l_value then
                    Result.put (
                        l_strategy.transform (l_value, rule.options),
                        rule.column
                    )
                elseif rule.options.preserve_nulls then
                    Result.put (Void, rule.column)
                end
            end
        end

end
```

### simple_sql Soft Delete Integration

**Purpose:** Handle GDPR "right to be forgotten" with soft deletes

**Usage:**
```eiffel
class ANONYMIZER_ENGINE

feature -- GDPR Compliance

    forget_user (a_user_id: INTEGER_64)
            -- Implement GDPR Article 17 "right to be forgotten"
            -- Soft deletes user and anonymizes remaining references
        local
            l_builder: SIMPLE_SQL_UPDATE_BUILDER
        do
            -- Soft delete the user record
            l_builder := database.update_builder
            l_builder.table ("users")
            l_builder.set ("deleted_at", current_timestamp)
            l_builder.where_equals ("id", a_user_id)
            l_builder.execute

            -- Anonymize references in other tables
            anonymize_user_references (a_user_id)

            -- Log for compliance
            log_forget_request (a_user_id)
        end

    query_active_users: SIMPLE_SQL_RESULT
            -- Query only non-deleted users
        do
            Result := database.select_builder
                .from_table ("users")
                .active_only  -- Uses soft delete scope
                .execute
        end

end
```

### simple_hash Integration

**Purpose:** One-way SHA-256 hashing for permanent anonymization

**Usage:**
```eiffel
class HASH_STRATEGY

inherit
    ANONYMIZATION_STRATEGY

feature -- Access

    name: STRING = "hash"
    is_reversible: BOOLEAN = False

feature -- Transformation

    transform (a_value: detachable ANY; a_options: ANONYMIZATION_OPTIONS): detachable ANY
        local
            l_hasher: SIMPLE_SHA256
            l_input: STRING
        do
            if a_value = Void then
                Result := Void
            else
                create l_hasher.make

                -- Combine value with salt for security
                l_input := a_value.out
                if attached a_options.salt as l_salt then
                    l_input := l_salt + l_input
                end

                -- Generate hash
                l_hasher.update_from_string (l_input)
                Result := l_hasher.digest_as_string

                -- Optionally truncate for readability
                if a_options.truncate_hash > 0 then
                    Result := Result.as_string_8.substring (1, a_options.truncate_hash)
                end
            end
        end

end
```

### simple_randomizer Integration

**Purpose:** Generate realistic fake data

**Usage:**
```eiffel
class FAKE_STRATEGY

inherit
    ANONYMIZATION_STRATEGY

feature -- Access

    name: STRING = "fake"
    is_reversible: BOOLEAN = False

feature {NONE} -- Implementation

    randomizer: SIMPLE_RANDOMIZER
            -- Shared randomizer for deterministic output

feature -- Initialization

    make_with_seed (a_seed: INTEGER)
            -- Create with deterministic seed for reproducibility
        do
            create randomizer.make_with_seed (a_seed)
        end

feature -- Transformation

    transform (a_value: detachable ANY; a_options: ANONYMIZATION_OPTIONS): detachable ANY
        do
            if a_value = Void then
                Result := Void
            else
                inspect a_options.fake_type
                when "email" then
                    Result := generate_email (a_options)
                when "first_name" then
                    Result := randomizer.first_name
                when "last_name" then
                    Result := randomizer.last_name
                when "full_name" then
                    Result := randomizer.full_name
                when "phone" then
                    Result := randomizer.phone_number
                when "address" then
                    Result := randomizer.street_address
                when "city" then
                    Result := randomizer.city
                when "state" then
                    Result := randomizer.state
                when "zip" then
                    Result := randomizer.zip_code
                when "country" then
                    Result := randomizer.country
                when "company" then
                    Result := randomizer.company_name
                when "ssn" then
                    Result := randomizer.ssn
                when "credit_card" then
                    Result := randomizer.credit_card_number
                when "date" then
                    Result := randomizer.date_between (
                        a_options.date_min,
                        a_options.date_max
                    )
                else
                    -- Default: random string of same length
                    Result := randomizer.random_string (a_value.out.count)
                end
            end
        end

feature {NONE} -- Helpers

    generate_email (a_options: ANONYMIZATION_OPTIONS): STRING
            -- Generate fake email, optionally preserving domain
        local
            l_original: STRING
            l_domain: STRING
        do
            if a_options.preserve_domain and attached a_options.original_value as l_orig then
                l_original := l_orig.out
                if l_original.has ('@') then
                    l_domain := l_original.substring (
                        l_original.index_of ('@', 1) + 1,
                        l_original.count
                    )
                    Result := randomizer.username + "@" + l_domain
                else
                    Result := randomizer.email
                end
            else
                Result := randomizer.email
            end
        end

end
```

### simple_encryption Integration (Optional)

**Purpose:** Reversible AES encryption for development environments

**Usage:**
```eiffel
class ENCRYPT_STRATEGY

inherit
    ANONYMIZATION_STRATEGY

feature -- Access

    name: STRING = "encrypt"
    is_reversible: BOOLEAN = True

feature -- Initialization

    make_with_key (a_key: STRING)
            -- Create with encryption key
        do
            create cipher.make_with_key (a_key)
        end

feature -- Transformation

    transform (a_value: detachable ANY; a_options: ANONYMIZATION_OPTIONS): detachable ANY
        do
            if a_value = Void then
                Result := Void
            else
                Result := cipher.encrypt (a_value.out)
            end
        end

    reverse (a_value: detachable ANY; a_options: ANONYMIZATION_OPTIONS): detachable ANY
        do
            if a_value = Void then
                Result := Void
            elseif attached {STRING} a_value as l_encrypted then
                Result := cipher.decrypt (l_encrypted)
            end
        end

feature {NONE} -- Implementation

    cipher: SIMPLE_AES_256

end
```

---

## Dependency Graph

```
data-anonymizer
    |
    +-- simple_sql (required)
    |       |
    |       +-- SIMPLE_SQL_DATABASE
    |       +-- SIMPLE_SQL_CURSOR (streaming)
    |       +-- SIMPLE_SQL_REPOSITORY
    |       +-- SIMPLE_SQL_SELECT_BUILDER (soft delete scopes)
    |       +-- SIMPLE_SQL_SCHEMA (table introspection)
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
    |
    +-- simple_hash (required)
    |       |
    |       +-- SIMPLE_SHA256
    |       +-- SIMPLE_MD5 (optional)
    |
    +-- simple_randomizer (required)
    |       |
    |       +-- SIMPLE_RANDOMIZER
    |       +-- SIMPLE_FAKER (names, addresses, etc.)
    |
    +-- simple_encryption (optional)
    |       |
    |       +-- SIMPLE_AES_256
    |
    +-- simple_csv (optional)
    |       |
    |       +-- SIMPLE_CSV_WRITER
    |
    +-- simple_regex (optional)
    |       |
    |       +-- SIMPLE_REGEX
    |
    +-- simple_validation (optional)
    |       |
    |       +-- SIMPLE_VALIDATOR
    |
    +-- ISE base (required)
            |
            +-- ARRAYED_LIST
            +-- HASH_TABLE
```

---

## ECF Configuration

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<system xmlns="http://www.eiffel.com/developers/xml/configuration-1-23-0"
        name="data_anonymizer" uuid="DATA-ANONYMIZER-UUID-HERE">

    <description>DATA-ANONYMIZER: GDPR/CCPA-Compliant Data Anonymization for SQLite</description>

    <!-- Library target -->
    <target name="data_anonymizer">
        <root all_classes="true"/>
        <option warning="warning" syntax="standard">
            <assertions precondition="true" postcondition="true" check="true"/>
        </option>

        <cluster name="src" location=".\src\" recursive="true"/>

        <!-- Required simple_* libraries -->
        <library name="simple_sql" location="$SIMPLE_EIFFEL\simple_sql\simple_sql.ecf"/>
        <library name="simple_json" location="$SIMPLE_EIFFEL\simple_json\simple_json.ecf"/>
        <library name="simple_cli" location="$SIMPLE_EIFFEL\simple_cli\simple_cli.ecf"/>
        <library name="simple_hash" location="$SIMPLE_EIFFEL\simple_hash\simple_hash.ecf"/>
        <library name="simple_randomizer" location="$SIMPLE_EIFFEL\simple_randomizer\simple_randomizer.ecf"/>

        <!-- Optional simple_* libraries -->
        <library name="simple_encryption" location="$SIMPLE_EIFFEL\simple_encryption\simple_encryption.ecf"/>
        <library name="simple_csv" location="$SIMPLE_EIFFEL\simple_csv\simple_csv.ecf"/>
        <library name="simple_regex" location="$SIMPLE_EIFFEL\simple_regex\simple_regex.ecf"/>
        <library name="simple_validation" location="$SIMPLE_EIFFEL\simple_validation\simple_validation.ecf"/>

        <!-- ISE libraries -->
        <library name="base" location="$ISE_LIBRARY\library\base\base.ecf"/>
    </target>

    <!-- CLI executable -->
    <target name="data_anonymizer_cli" extends="data_anonymizer">
        <root class="DATA_ANONYMIZER_CLI" feature="make"/>
        <setting name="executable_name" value="data-anonymizer"/>
    </target>

    <!-- Test target -->
    <target name="data_anonymizer_tests" extends="data_anonymizer">
        <root class="TEST_APP" feature="make"/>
        <library name="simple_testing" location="$SIMPLE_EIFFEL\simple_testing\simple_testing.ecf"/>
        <cluster name="tests" location=".\tests\" recursive="true"/>
    </target>

</system>
```

---

## Integration Test Scenarios

### Scenario 1: Scan and Generate Rules
```bash
# Scan database for PII
data-anonymizer scan --db customers.db
# Output: Detected email, phone, ssn, name columns

# Generate rules from scan
data-anonymizer rules generate --db customers.db --output rules.json
# Creates rules.json with detected columns
```

### Scenario 2: Anonymize Database
```bash
# Anonymize with generated rules
data-anonymizer anonymize --db customers.db --config rules.json --output test.db

# Verify anonymization
data-anonymizer verify --db test.db --config rules.json
# Expected: PASS - all PII transformed
```

### Scenario 3: Reversible Anonymization
```bash
# Generate encryption key
openssl rand -base64 32 > secret.key

# Anonymize with encryption (reversible)
data-anonymizer anonymize --db dev.db --config rules-reversible.json --key secret.key

# Later: reverse when needed
data-anonymizer reverse --db dev.db --key secret.key
```

### Scenario 4: CI/CD Pipeline Check
```bash
# Check for PII in test database (fail CI if found)
data-anonymizer scan --db test.db --check
# Exit code 10 if PII detected
```
