# DB-AUDITOR - Build Plan

---

## Phase Overview

| Phase | Deliverable | Effort | Dependencies |
|-------|-------------|--------|--------------|
| Phase 1 | MVP CLI (setup, query, basic export) | 3 days | simple_sql, simple_cli, simple_json |
| Phase 2 | Full CLI (reports, analyze) | 3 days | Phase 1 + simple_template, simple_datetime |
| Phase 3 | Enterprise (integrity, alerts) | 2 days | Phase 2 + simple_hash, simple_http |

---

## Phase 1: MVP

### Objective

Deliver a functional CLI that can enable auditing on SQLite tables, query change history, and export audit data. This proves the core value proposition.

### Deliverables

1. **DB_AUDITOR_CLI** - Main CLI entry point with command routing
2. **AUDITOR_ENGINE** - Core business logic orchestration
3. **AUDITOR_SETUP** - Enable/disable/status for table auditing
4. **AUDITOR_QUERY** - Query changes with filtering
5. **AUDIT_CHANGE** - Entity class for change records
6. **Basic CLI** - setup, query, export commands

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T1.1 | Create project structure and ECF | Project compiles with all dependencies |
| T1.2 | Implement DB_AUDITOR_CLI | `db-auditor --help` shows usage |
| T1.3 | Implement AUDITOR_ENGINE | Can open database and access audit module |
| T1.4 | Implement AUDITOR_SETUP | `setup enable/disable/status` work |
| T1.5 | Implement AUDIT_CHANGE entity | Can parse audit row to entity |
| T1.6 | Implement AUDITOR_QUERY | Can query by table, record, time |
| T1.7 | Implement export command | JSON and CSV export work |
| T1.8 | Write unit tests | 80% code coverage |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| test_setup_enable | `setup --db test.db enable users` | Audit triggers created |
| test_setup_disable | `setup --db test.db disable users` | Audit triggers removed |
| test_setup_status | `setup --db test.db status` | Table list with status |
| test_query_by_table | `query --db test.db --table users` | Changes for users table |
| test_query_by_time | `query --db test.db --since "2026-01-01"` | Changes after date |
| test_export_json | `export --db test.db --output audit.json` | Valid JSON file |
| test_export_csv | `export --db test.db --output audit.csv` | Valid CSV file |

### Definition of Done (Phase 1)

- [ ] All commands work: setup, query, export
- [ ] JSON and text output formats work
- [ ] Unit tests pass (80% coverage)
- [ ] README with usage examples
- [ ] Can be installed and run on clean system

---

## Phase 2: Full Implementation

### Objective

Add compliance reporting, anomaly detection, and configuration management. This completes the Pro feature set.

### Deliverables

1. **AUDITOR_REPORTER** - Report generation with templates
2. **AUDITOR_ANALYZER** - Anomaly detection patterns
3. **AUDITOR_CONFIG** - Configuration file management
4. **COMPLIANCE_TEMPLATE** - SOX, HIPAA, PCI-DSS, GDPR templates
5. **report command** - Full reporting functionality
6. **analyze command** - Anomaly detection
7. **config command** - Configuration management

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T2.1 | Implement AUDITOR_CONFIG | Load/save JSON config |
| T2.2 | Implement COMPLIANCE_TEMPLATE | 4 templates render correctly |
| T2.3 | Implement AUDITOR_REPORTER | HTML report generation |
| T2.4 | Implement report command | All templates work |
| T2.5 | Implement AUDITOR_ANALYZER | Pattern detection works |
| T2.6 | Implement analyze command | bulk-deletes, off-hours work |
| T2.7 | Add time period support | today, week, month, quarter, year |
| T2.8 | Integration tests | End-to-end scenarios pass |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| test_report_sox | `report --template sox --period month` | SOX-compliant HTML |
| test_report_hipaa | `report --template hipaa` | HIPAA report |
| test_analyze_bulk | `analyze --detect bulk-deletes` | Bulk delete alerts |
| test_analyze_offhours | `analyze --detect off-hours` | Off-hours alerts |
| test_config_load | `config show` | Current config displayed |
| test_config_set | `config set retention_days 180` | Config updated |

### Definition of Done (Phase 2)

- [ ] All compliance templates work
- [ ] Anomaly detection finds test cases
- [ ] Configuration persists between runs
- [ ] Integration tests pass
- [ ] Documentation for all features

---

## Phase 3: Production Polish

### Objective

Add enterprise features: integrity verification, alerting, and hardening for production use.

### Deliverables

1. **Integrity verification** - Hash chain validation
2. **Alert notifications** - Email and webhook support
3. **verify command** - Audit trail integrity check
4. **Performance optimization** - Large dataset handling
5. **Error handling hardening** - All edge cases covered

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T3.1 | Implement hash chain integrity | Tampering detected |
| T3.2 | Implement verify command | `verify` detects tampering |
| T3.3 | Add webhook notifications | POST to URL works |
| T3.4 | Performance testing | 1M records in <5 seconds |
| T3.5 | Error handling review | All errors have clear messages |
| T3.6 | Security review | No SQL injection, safe file handling |
| T3.7 | Documentation complete | Full user guide |
| T3.8 | Release preparation | Binaries, installer, changelog |

### Definition of Done (Phase 3)

- [ ] Integrity verification works
- [ ] Webhook alerts fire correctly
- [ ] Performance meets targets
- [ ] All edge cases handled
- [ ] User documentation complete
- [ ] Release package ready

---

## ECF Target Structure

```xml
<!-- Library target (reusable) -->
<target name="db_auditor">
    <root all_classes="true"/>
    <cluster name="src" location=".\src\" recursive="true"/>
    <library name="simple_sql" location="$SIMPLE_EIFFEL\simple_sql\simple_sql.ecf"/>
    <library name="simple_json" location="$SIMPLE_EIFFEL\simple_json\simple_json.ecf"/>
    <library name="simple_cli" location="$SIMPLE_EIFFEL\simple_cli\simple_cli.ecf"/>
    <library name="simple_datetime" location="$SIMPLE_EIFFEL\simple_datetime\simple_datetime.ecf"/>
    <library name="simple_csv" location="$SIMPLE_EIFFEL\simple_csv\simple_csv.ecf"/>
    <library name="simple_template" location="$SIMPLE_EIFFEL\simple_template\simple_template.ecf"/>
    <library name="base" location="$ISE_LIBRARY\library\base\base.ecf"/>
    <library name="time" location="$ISE_LIBRARY\library\time\time.ecf"/>
</target>

<!-- CLI executable target -->
<target name="db_auditor_cli" extends="db_auditor">
    <root class="DB_AUDITOR_CLI" feature="make"/>
    <setting name="executable_name" value="db-auditor"/>
</target>

<!-- Test target -->
<target name="db_auditor_tests" extends="db_auditor">
    <root class="TEST_APP" feature="make"/>
    <library name="simple_testing" location="$SIMPLE_EIFFEL\simple_testing\simple_testing.ecf"/>
    <cluster name="tests" location=".\tests\" recursive="true"/>
</target>
```

---

## Build Commands

```bash
# Compile CLI (workbench)
/d/prod/ec.sh -batch -config db_auditor.ecf -target db_auditor_cli -c_compile

# Compile CLI (finalized for release)
/d/prod/ec.sh -batch -config db_auditor.ecf -target db_auditor_cli -finalize -c_compile

# Run tests
/d/prod/ec.sh -batch -config db_auditor.ecf -target db_auditor_tests -c_compile
./EIFGENs/db_auditor_tests/W_code/db_auditor.exe

# Run CLI
./EIFGENs/db_auditor_cli/W_code/db-auditor.exe --help
```

---

## Success Criteria

| Criterion | Measure | Target |
|-----------|---------|--------|
| Compiles | Zero errors | 100% |
| Tests pass | All tests | 100% |
| CLI works | All commands | Functional |
| Documentation | README complete | Yes |
| Performance | 1M records query | <5 seconds |
| Compliance | SOX report accuracy | Verified by auditor |

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| simple_sql audit API changes | Pin to specific version, add adapter layer |
| Large dataset performance | Streaming queries, pagination |
| Template rendering complexity | Use simple_template, fallback to plain text |
| Cross-platform issues | Test on Windows/Linux/macOS |

---

## File Structure

```
db_auditor/
├── db_auditor.ecf
├── README.md
├── CHANGELOG.md
├── LICENSE
├── src/
│   ├── db_auditor_cli.e
│   ├── auditor_engine.e
│   ├── auditor_setup.e
│   ├── auditor_query.e
│   ├── auditor_reporter.e
│   ├── auditor_analyzer.e
│   ├── auditor_config.e
│   ├── entities/
│   │   ├── audit_change.e
│   │   ├── audit_report.e
│   │   └── compliance_template.e
│   └── commands/
│       ├── setup_command.e
│       ├── query_command.e
│       ├── report_command.e
│       ├── analyze_command.e
│       └── export_command.e
├── templates/
│   ├── sox.html
│   ├── hipaa.html
│   ├── pci-dss.html
│   └── gdpr.html
├── tests/
│   ├── test_app.e
│   ├── test_auditor_setup.e
│   ├── test_auditor_query.e
│   ├── test_auditor_reporter.e
│   └── test_auditor_analyzer.e
└── docs/
    ├── index.html
    ├── getting-started.html
    └── api/
        └── ...
```
