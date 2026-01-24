# S04-FEATURE-SPECS: simple_sql

**BACKWASH** | Date: 2026-01-23

## SIMPLE_SQL_REPOSITORY Features

### Query Features

| Feature | Signature | Description |
|---------|-----------|-------------|
| find_all | : ARRAYED_LIST [G] | Return all entities |
| find_all_ordered | (order_by: STRING_8): ARRAYED_LIST [G] | All entities ordered |
| find_all_limited | (limit, offset: INTEGER): ARRAYED_LIST [G] | Paginated entities |
| find_by_id | (id: INTEGER_64): detachable G | Find by primary key |
| exists | (id: INTEGER_64): BOOLEAN | Check existence |
| find_where | (conditions: STRING_8): ARRAYED_LIST [G] | Find by conditions |
| find_first_where | (conditions: STRING_8): detachable G | First matching |
| count | : INTEGER | Total count |
| count_where | (conditions: STRING_8): INTEGER | Conditional count |

### Command Features

| Feature | Signature | Description |
|---------|-----------|-------------|
| insert | (entity: G): INTEGER_64 | Insert, return ID |
| update | (entity: G): BOOLEAN | Update by ID |
| update_where | (cols: HASH_TABLE; where: STRING_8): INTEGER | Bulk update |
| delete | (id: INTEGER_64): BOOLEAN | Delete by ID |
| delete_where | (conditions: STRING_8): INTEGER | Bulk delete |
| delete_all | : INTEGER | Delete all |
| save | (entity: G): INTEGER_64 | Insert or update |

### Deferred Features

| Feature | Must Override | Purpose |
|---------|---------------|---------|
| table_name | Yes | Database table name |
| primary_key_column | Yes | Primary key column name |
| row_to_entity | Yes | Map row to entity |
| entity_to_columns | Yes | Map entity to columns |
| entity_id | Yes | Extract entity ID |

## SIMPLE_SQL_PREPARED_STATEMENT Features

### Binding Features

| Feature | Signature | Description |
|---------|-----------|-------------|
| bind_integer | (index: INTEGER; value: INTEGER_64) | Bind integer |
| bind_real | (index: INTEGER; value: REAL_64) | Bind real |
| bind_text | (index: INTEGER; value: STRING_GENERAL) | Bind text |
| bind_blob | (index: INTEGER; value: MANAGED_POINTER) | Bind blob |
| bind_null | (index: INTEGER) | Bind NULL |
| bind_*_by_name | Same with name: STRING_8 | Named binding |

### Execution Features

| Feature | Signature | Description |
|---------|-----------|-------------|
| execute | | Execute statement |
| execute_returning_result | : SIMPLE_SQL_RESULT | Execute and get result |
| execute_cursor | : SIMPLE_SQL_CURSOR | Lazy iteration |
| execute_stream | : SIMPLE_SQL_RESULT_STREAM | Callback iteration |
| reset | | Clear bindings |
