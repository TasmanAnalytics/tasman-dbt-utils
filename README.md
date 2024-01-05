# tasman-dbt-utils

## What is tasman-dbt-utils?
`tasman-dbt-utils` is a dbt package with reusable macro's. It includes macro's for, but not limited to:
- tests
- monitoring & auditing
- SQL functions
- ops functions

The intention for this package is to have each macro available for [dbt-snowflake](https://github.com/dbt-labs/dbt-snowflake) and [dbt-bigquery](https://github.com/dbt-labs/dbt-bigquery). Some functions will be only available for one of the platforms because of the fundamental differences between them. For example managing warehouse-size's is only a thing in Snowflake. This package does not intend to replace other packages which are commonly used such as [dbt-utils](https://github.com/dbt-labs/dbt-utils) or [dbt-expectations](https://github.com/calogica/dbt-expectations). This package add's functionalities which those package's don't provide.

## Installation

This package isn't currently publicly available and requires a token supplied by Tasman Analytics. It's best practice to use environment variables to store the token. You can do this locally by adding the following to your terminal configuration file (.zprofile or .zsh depending on your terminal)

```
export DBT_ENV_SECRET_GIT_CREDENTIAL="<token>"
```

For production runs, this will also need to be added to your production configuration. For dbt Cloud users, please follow [this](https://docs.getdbt.com/docs/build/packages) guide.

With the environment variable, you can use a git reference in the packages.yml file.

```
packages:
    - git: https://{{env_var('DBT_ENV_SECRET_GIT_CREDENTIAL')}}@github.com/TasmanAnalytics/tasman-dbt-utils.git
      revision: 0.1
```

## Macro's & tests
- [Tests](#tests)
- [SQL Functions](#sql-functions)
	- [include](#include)
- [Monitoring & auditing](#monitoring--auditing)
	- [do_table_scan](#do_table_scan)
- [Ops](#ops)
	- [set_warehouse_size](#set_warehouse)
	- [drop_old_relations](#drop_old_relations)

### Tests

### SQL Functions

#### Include

### Monitoring & auditing
#### [do_table_scan](macros/do_table_scan.sql)
Prints a summary of statistics about the target model to the terminal.
```
| database_name   | schema_name | table_name | column_name          | ordinal_position | row_count | distinct_count | null_count | is_unique | max        | min        |     avg |
| --------------- | ----------- | ---------- | -------------------- | ---------------- | --------- | -------------- | ---------- | --------- | ---------- | ---------- | ------- |
| tasman-internal | dbt_jurri   | customers  | customer_id          |                1 |       100 |            100 |          0 |      True | 100        | 1          | 50.500… |
| tasman-internal | dbt_jurri   | customers  | first_name           |                2 |       100 |             79 |          0 |     False |            |            |         |
| tasman-internal | dbt_jurri   | customers  | last_name            |                3 |       100 |             19 |          0 |     False |            |            |         |
| tasman-internal | dbt_jurri   | customers  | first_order          |                4 |       100 |             46 |         38 |     False | 2018-04-07 | 2018-01-01 |         |
| tasman-internal | dbt_jurri   | customers  | most_recent_order    |                5 |       100 |             52 |         38 |     False | 2018-04-09 | 2018-01-09 |         |
| tasman-internal | dbt_jurri   | customers  | number_of_orders     |                6 |       100 |              4 |         38 |     False | 5          | 1          |  1.597… |
| tasman-internal | dbt_jurri   | customers  | customer_lifetime... |                7 |       100 |             35 |         38 |     False | 99         | 1          | 26.968… |
```

| Platform  | Support |
| --------- | ------- |
| BigQuery  | ✅      |
| Snowflake | ✅      |

_Scope: model, seed, snapshot_

**Arguments**
- `table`: the name of the table it should do the table scan on.
- `schema` (optional, default=target.schema): the schema of where the target table is located.
- `database` (optional, default=target.database): the database of where the target table is located.
 
### [get_object_keys](macros/get_object_keys.sql)
Gets all of the object keys (including nested keys) of a column and prints them to the terminal.

| Platform  | Support |
| --------- | ------- |
| BigQuery  | ❌      |
| Snowflake | ✅      |

_Scope: model, snapshot_

**Argements**
- `column`: the name of the object column.
- `table`: the name of the target table.
- `schema` (optional, default=target.schema): the schema of where the target table is located.
- `database` (optional, default=target.database): the database of where the target table is located.

### Ops
#### [set_warehouse_size](macros/set_warehouse_size.sql)
Sets a custom warehouse size for individual models.

| Platform  | Support |
| --------- | ------- |
| BigQuery  | ❌      |
| Snowflake | ✅      |

_Scope: model, snapshot_

**Arguments**
- `size` (required): the size of the warehouse

**Usage**
```
{{
    config(
        snowflake_warehouse=set_warehouse('M')
    )
}}
```
This requires a list of available warehouse size's to be set in the dbt_project.yml
```
vars:
	tasman_dbt_utils:
		available_warehouse_sizes: ['XS', 'S', 'M']
```

#### [drop_old_relations](macros/drop_old_relations.sql)
This macro takes the relations in the manifest and compares it to the tables and views in the warehouse. Tables and views which are in the warehouse but not in the manifest will be dropped.

| Platform  | Support |
| --------- | ------- |
| BigQuery  | ❌      |
| Snowflake | ✅      |

_Scope: model, seed, snapshot_

**Arguments**
- `schema_prefix` (optional, default=target.schema): the prefix of the schema's where the relations should be deleted. 
- `database` (optional, default=target.database): the database where the relations should be deleted.
- `dry_run` (optional, default=True): when set to True it will print the statements, when set to False it will actually remove the relations.

**Usage**
```
dbt run-operation drop_old_relations --args '{dry_run: False, schema: dbt}'
```