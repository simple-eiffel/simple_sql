# DATA-MIGRATOR - Build Plan

---

## Phase Overview

| Phase | Deliverable | Effort | Dependencies |
|-------|-------------|--------|--------------|
| Phase 1 | MVP (init, create, up, status) | 2 days | simple_sql, simple_cli, simple_json, simple_file |
| Phase 2 | Pro (down, diff, generate, profiles) | 3 days | Phase 1 + simple_diff, simple_hash |
| Phase 3 | Enterprise (ETL, seed, team features) | 3 days | Phase 2 + simple_csv |

---

## Phase 1: MVP (Open Core)

### Objective

Deliver a functional CLI that can initialize a migrations directory, create migration files, run pending migrations, and show status. This covers the basic workflow that 80% of users need.

### Deliverables

1. **DATA_MIGRATOR_CLI** - Main CLI entry point
2. **MIGRATOR_ENGINE** - Core orchestration
3. **MIGRATOR_RUNNER** - Migration execution
4. **MIGRATION** - Migration entity class
5. **MIGRATION_PARSER** - Parse SQL migration files
6. **Basic CLI** - init, create, up, status commands

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T1.1 | Create project structure and ECF | Project compiles |
| T1.2 | Implement DATA_MIGRATOR_CLI | `data-migrator --help` works |
| T1.3 | Implement init command | Creates migrations/ and config |
| T1.4 | Implement MIGRATION_PARSER | Parses -- +up/+down sections |
| T1.5 | Implement create command | Creates timestamped file |
| T1.6 | Implement MIGRATOR_RUNNER | Executes migrations in order |
| T1.7 | Implement up command | Runs pending migrations |
| T1.8 | Implement status command | Shows applied/pending |
| T1.9 | Write unit tests | 80% coverage |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| test_init | `init` | ./migrations/ created |
| test_create | `create add_users` | Timestamped file created |
| test_parse_migration | SQL file with +up/+down | Correctly parsed |
| test_up_single | `up --db test.db` | Migration applied |
| test_up_multiple | Multiple pending | All applied in order |
| test_status_empty | Fresh database | "No migrations applied" |
| test_status_applied | After up | Shows applied migrations |

### Definition of Done (Phase 1)

- [ ] init, create, up, status commands work
- [ ] Migrations execute correctly
- [ ] Status reflects PRAGMA user_version
- [ ] Unit tests pass
- [ ] README with quickstart guide

---

## Phase 2: Pro Features

### Objective

Add rollback capability, schema comparison, migration generation, and environment profiles. This completes the Pro feature set.

### Deliverables

1. **MIGRATOR_DIFF** - Schema comparison
2. **SCHEMA_DIFF** - Diff result entity
3. **Down migrations** - Rollback support
4. **generate command** - Auto-generate from diff
5. **diff command** - Compare databases
6. **Environment profiles** - Dev/staging/prod configs

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T2.1 | Implement down parsing | +down section parsed |
| T2.2 | Implement down command | Rollback works |
| T2.3 | Implement MIGRATOR_DIFF | Compares schemas |
| T2.4 | Implement diff command | Shows differences |
| T2.5 | Implement SCHEMA_DIFF.to_sql | Generates SQL |
| T2.6 | Implement generate command | Creates migration file |
| T2.7 | Add environment profiles | --env flag works |
| T2.8 | Add dry-run mode | Shows SQL without executing |
| T2.9 | Add checksum verification | Detects modified migrations |
| T2.10 | Integration tests | End-to-end scenarios pass |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| test_down_single | `down --db test.db` | One rollback |
| test_down_steps | `down --steps 3` | Three rollbacks |
| test_diff_identical | Same schema | "No differences" |
| test_diff_added_table | New table in target | Shows added |
| test_diff_modified_column | Changed column | Shows modification |
| test_generate | Two different DBs | Valid migration SQL |
| test_env_profile | `--env production` | Uses prod config |
| test_dry_run | `up --dry-run` | Shows SQL, no changes |

### Definition of Done (Phase 2)

- [ ] Rollback works correctly
- [ ] Schema diff detects all changes
- [ ] Generated migrations are valid SQL
- [ ] Profiles switch databases correctly
- [ ] Integration tests pass

---

## Phase 3: Enterprise Features

### Objective

Add ETL pipeline support, data seeding, and team collaboration features.

### Deliverables

1. **MIGRATOR_ETL** - Data transformation pipeline
2. **export command** - Export to CSV/JSON/SQL
3. **import command** - Import from files
4. **seed command** - Run seed data files
5. **Team features** - Shared migration registry
6. **Audit trail** - Migration history logging

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T3.1 | Implement export command | CSV/JSON/SQL export |
| T3.2 | Implement import command | CSV/JSON import |
| T3.3 | Implement seed command | Run seed files |
| T3.4 | Implement _migrator_history table | Detailed tracking |
| T3.5 | Add --check flag for CI/CD | Exit 10 if pending |
| T3.6 | Performance optimization | 1000 migrations in <5s |
| T3.7 | Documentation complete | Full user guide |
| T3.8 | Release preparation | Binaries, installer |

### Definition of Done (Phase 3)

- [ ] ETL pipeline works
- [ ] Seed data works
- [ ] Performance targets met
- [ ] Full documentation
- [ ] Release package ready

---

## ECF Target Structure

```xml
<!-- Library target -->
<target name="data_migrator">
    <cluster name="src" location=".\src\" recursive="true"/>
    <library name="simple_sql" location="$SIMPLE_EIFFEL\simple_sql\simple_sql.ecf"/>
    <library name="simple_json" location="$SIMPLE_EIFFEL\simple_json\simple_json.ecf"/>
    <library name="simple_cli" location="$SIMPLE_EIFFEL\simple_cli\simple_cli.ecf"/>
    <library name="simple_file" location="$SIMPLE_EIFFEL\simple_file\simple_file.ecf"/>
    <library name="simple_diff" location="$SIMPLE_EIFFEL\simple_diff\simple_diff.ecf"/>
    <library name="simple_csv" location="$SIMPLE_EIFFEL\simple_csv\simple_csv.ecf"/>
    <library name="simple_hash" location="$SIMPLE_EIFFEL\simple_hash\simple_hash.ecf"/>
    <library name="base" location="$ISE_LIBRARY\library\base\base.ecf"/>
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
```

---

## Build Commands

```bash
# Compile CLI
/d/prod/ec.sh -batch -config data_migrator.ecf -target data_migrator_cli -c_compile

# Finalize for release
/d/prod/ec.sh -batch -config data_migrator.ecf -target data_migrator_cli -finalize -c_compile

# Run tests
/d/prod/ec.sh -batch -config data_migrator.ecf -target data_migrator_tests -c_compile
./EIFGENs/data_migrator_tests/W_code/data_migrator.exe

# Run CLI
./EIFGENs/data_migrator_cli/W_code/data-migrator.exe --help
```

---

## Success Criteria

| Criterion | Measure | Target |
|-----------|---------|--------|
| Compiles | Zero errors | 100% |
| Tests pass | All tests | 100% |
| Migration speed | 100 migrations | <1 second |
| Schema diff | All differences detected | 100% |
| Rollback | Clean rollback | 100% |

---

## File Structure

```
data_migrator/
├── data_migrator.ecf
├── README.md
├── CHANGELOG.md
├── LICENSE
├── src/
│   ├── data_migrator_cli.e
│   ├── migrator_engine.e
│   ├── migrator_runner.e
│   ├── migrator_diff.e
│   ├── migrator_etl.e
│   ├── migrator_config.e
│   ├── entities/
│   │   ├── migration.e
│   │   ├── file_migration.e
│   │   ├── schema_diff.e
│   │   └── etl_pipeline.e
│   ├── parsers/
│   │   └── migration_parser.e
│   └── commands/
│       ├── init_command.e
│       ├── create_command.e
│       ├── up_command.e
│       ├── down_command.e
│       ├── status_command.e
│       ├── diff_command.e
│       └── generate_command.e
├── tests/
│   ├── test_app.e
│   ├── test_migrator_runner.e
│   ├── test_migrator_diff.e
│   └── test_migration_parser.e
└── docs/
    ├── index.html
    ├── getting-started.html
    └── api/
```
