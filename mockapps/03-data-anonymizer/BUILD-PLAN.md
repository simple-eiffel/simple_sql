# DATA-ANONYMIZER - Build Plan

---

## Phase Overview

| Phase | Deliverable | Effort | Dependencies |
|-------|-------------|--------|--------------|
| Phase 1 | MVP (scan, basic anonymize) | 3 days | simple_sql, simple_cli, simple_json, simple_hash |
| Phase 2 | Pro (fake data, verify, reversible) | 3 days | Phase 1 + simple_randomizer, simple_encryption |
| Phase 3 | Enterprise (GDPR tools, compliance) | 2 days | Phase 2 + simple_regex |

---

## Phase 1: MVP

### Objective

Deliver a functional CLI that can scan databases for PII, define anonymization rules, and apply basic transformations (hash, replace, null). This proves the core value proposition.

### Deliverables

1. **DATA_ANONYMIZER_CLI** - Main CLI entry point
2. **ANONYMIZER_ENGINE** - Core orchestration
3. **ANONYMIZER_SCANNER** - PII pattern detection
4. **ANONYMIZER_RULES** - Rule parsing and validation
5. **ANONYMIZER_TRANSFORM** - Transformation engine
6. **Basic strategies** - hash, replace, null, skip
7. **Basic CLI** - scan, rules, anonymize commands

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T1.1 | Create project structure and ECF | Project compiles |
| T1.2 | Implement DATA_ANONYMIZER_CLI | `data-anonymizer --help` works |
| T1.3 | Implement ANONYMIZER_SCANNER | Detects email, phone, SSN patterns |
| T1.4 | Implement scan command | Lists detected PII columns |
| T1.5 | Implement ANONYMIZER_RULES | Loads/validates JSON rules |
| T1.6 | Implement rules command | generate, validate, show work |
| T1.7 | Implement HASH_STRATEGY | SHA-256 hashing with salt |
| T1.8 | Implement REPLACE_STRATEGY | Replace with constant |
| T1.9 | Implement NULL_STRATEGY | Set to NULL |
| T1.10 | Implement ANONYMIZER_TRANSFORM | Processes tables via streaming |
| T1.11 | Implement anonymize command | Creates anonymized copy |
| T1.12 | Write unit tests | 80% coverage |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| test_scan_email | Column with email addresses | Detected as EMAIL |
| test_scan_phone | Column with phone numbers | Detected as PHONE |
| test_scan_ssn | Column with SSN format | Detected as SSN |
| test_hash_transform | "alice@test.com" | SHA-256 hash |
| test_replace_transform | "secret" | Replaced constant |
| test_null_transform | "value" | NULL |
| test_anonymize_table | Table with PII | All PII transformed |
| test_preserve_nulls | NULL values | Still NULL |

### Definition of Done (Phase 1)

- [ ] scan command detects common PII
- [ ] rules command generates valid rules
- [ ] anonymize command creates anonymized copy
- [ ] Unit tests pass
- [ ] README with quickstart

---

## Phase 2: Pro Features

### Objective

Add realistic fake data generation, verification, and reversible encryption. This completes the Pro feature set for development teams.

### Deliverables

1. **FAKE_STRATEGY** - Realistic fake data
2. **MASK_STRATEGY** - Partial masking
3. **SHUFFLE_STRATEGY** - Distribution-preserving shuffle
4. **ENCRYPT_STRATEGY** - Reversible AES encryption
5. **ANONYMIZER_VERIFY** - Verification engine
6. **verify command** - Check anonymization completeness
7. **reverse command** - Reverse encrypted data

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T2.1 | Implement FAKE_STRATEGY | Generates realistic names, emails, etc. |
| T2.2 | Implement MASK_STRATEGY | Partial reveal patterns |
| T2.3 | Implement SHUFFLE_STRATEGY | Preserves distribution |
| T2.4 | Implement ENCRYPT_STRATEGY | AES-256 encryption |
| T2.5 | Implement ANONYMIZER_VERIFY | Checks for remaining PII |
| T2.6 | Implement verify command | Reports verification results |
| T2.7 | Implement reverse command | Reverses encryption |
| T2.8 | Add FK preservation | Maintains referential integrity |
| T2.9 | Add deterministic mode | Same input = same output |
| T2.10 | Integration tests | End-to-end scenarios pass |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| test_fake_email | Email column | Realistic fake emails |
| test_fake_name | Name column | Realistic names |
| test_mask_email | "alice@test.com" | "a****@t***.com" |
| test_shuffle_ages | Age column | Same distribution, different order |
| test_encrypt_decrypt | "secret" -> encrypted -> "secret" | Reversible |
| test_verify_pass | Anonymized DB | PASS result |
| test_verify_fail | DB with remaining PII | FAIL result |
| test_fk_integrity | DB with FKs | All FKs valid after anonymization |

### Definition of Done (Phase 2)

- [ ] All strategies implemented
- [ ] Verification detects remaining PII
- [ ] Reversible encryption works
- [ ] FK integrity maintained
- [ ] Integration tests pass

---

## Phase 3: Enterprise Features

### Objective

Add GDPR compliance tools, re-identification risk analysis, and compliance reporting.

### Deliverables

1. **GDPR forget feature** - Article 17 compliance
2. **Audit trail** - Track all anonymizations
3. **audit command** - Generate compliance reports
4. **Re-identification risk** - Analyze anonymization strength
5. **Custom patterns** - User-defined PII patterns
6. **Compliance templates** - Pre-built GDPR/HIPAA/PCI rules

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T3.1 | Implement forget feature | Soft delete + anonymize references |
| T3.2 | Implement audit trail | All transformations logged |
| T3.3 | Implement audit command | Generates compliance report |
| T3.4 | Add custom pattern support | User regex patterns work |
| T3.5 | Create GDPR template | Pre-built rules for GDPR |
| T3.6 | Create HIPAA template | Pre-built rules for HIPAA |
| T3.7 | Performance optimization | 10K records/sec |
| T3.8 | Documentation complete | Full user guide |
| T3.9 | Release preparation | Binaries, installer |

### Definition of Done (Phase 3)

- [ ] GDPR forget works
- [ ] Audit trail complete
- [ ] Compliance templates included
- [ ] Performance targets met
- [ ] Full documentation
- [ ] Release package ready

---

## ECF Target Structure

```xml
<!-- Library target -->
<target name="data_anonymizer">
    <cluster name="src" location=".\src\" recursive="true"/>
    <library name="simple_sql" location="$SIMPLE_EIFFEL\simple_sql\simple_sql.ecf"/>
    <library name="simple_json" location="$SIMPLE_EIFFEL\simple_json\simple_json.ecf"/>
    <library name="simple_cli" location="$SIMPLE_EIFFEL\simple_cli\simple_cli.ecf"/>
    <library name="simple_hash" location="$SIMPLE_EIFFEL\simple_hash\simple_hash.ecf"/>
    <library name="simple_randomizer" location="$SIMPLE_EIFFEL\simple_randomizer\simple_randomizer.ecf"/>
    <library name="simple_encryption" location="$SIMPLE_EIFFEL\simple_encryption\simple_encryption.ecf"/>
    <library name="simple_regex" location="$SIMPLE_EIFFEL\simple_regex\simple_regex.ecf"/>
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
```

---

## Build Commands

```bash
# Compile CLI
/d/prod/ec.sh -batch -config data_anonymizer.ecf -target data_anonymizer_cli -c_compile

# Finalize for release
/d/prod/ec.sh -batch -config data_anonymizer.ecf -target data_anonymizer_cli -finalize -c_compile

# Run tests
/d/prod/ec.sh -batch -config data_anonymizer.ecf -target data_anonymizer_tests -c_compile
./EIFGENs/data_anonymizer_tests/W_code/data_anonymizer.exe

# Run CLI
./EIFGENs/data_anonymizer_cli/W_code/data-anonymizer.exe --help
```

---

## Success Criteria

| Criterion | Measure | Target |
|-----------|---------|--------|
| Compiles | Zero errors | 100% |
| Tests pass | All tests | 100% |
| Anonymization speed | 10K records | <1 second |
| PII detection | Common patterns | 95% recall |
| Verification | Detects remaining PII | 100% |
| FK integrity | All FKs valid | 100% |

---

## File Structure

```
data_anonymizer/
├── data_anonymizer.ecf
├── README.md
├── CHANGELOG.md
├── LICENSE
├── src/
│   ├── data_anonymizer_cli.e
│   ├── anonymizer_engine.e
│   ├── anonymizer_scanner.e
│   ├── anonymizer_rules.e
│   ├── anonymizer_transform.e
│   ├── anonymizer_verify.e
│   ├── entities/
│   │   ├── anonymization_rule.e
│   │   ├── anonymization_options.e
│   │   └── pii_detection.e
│   ├── strategies/
│   │   ├── anonymization_strategy.e
│   │   ├── hash_strategy.e
│   │   ├── replace_strategy.e
│   │   ├── null_strategy.e
│   │   ├── fake_strategy.e
│   │   ├── mask_strategy.e
│   │   ├── shuffle_strategy.e
│   │   └── encrypt_strategy.e
│   ├── patterns/
│   │   ├── pii_pattern.e
│   │   ├── email_pattern.e
│   │   ├── phone_pattern.e
│   │   └── ssn_pattern.e
│   └── commands/
│       ├── scan_command.e
│       ├── rules_command.e
│       ├── anonymize_command.e
│       ├── verify_command.e
│       ├── reverse_command.e
│       └── audit_command.e
├── templates/
│   ├── gdpr.json
│   ├── hipaa.json
│   └── pci-dss.json
├── tests/
│   ├── test_app.e
│   ├── test_scanner.e
│   ├── test_strategies.e
│   ├── test_transform.e
│   └── test_verify.e
└── docs/
    ├── index.html
    ├── getting-started.html
    ├── strategies.html
    └── api/
```

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| PII pattern false negatives | Multiple pattern strategies, user-defined patterns |
| Performance on large DBs | Streaming with cursors, batch processing |
| FK integrity issues | Analyze FK graph before anonymization |
| Encryption key management | Clear documentation, key file validation |
| Cross-platform regex | Use simple_regex with consistent engine |
