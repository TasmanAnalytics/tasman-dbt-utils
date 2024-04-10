# tasman_dbt_utils

## What is tasman_dbt_utils?
`tasman_dbt_utils` is a dbt package with reusable macro's. It includes macro's for, but not limited to:
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
    - git: https://{{env_var('DBT_ENV_SECRET_GIT_CREDENTIAL')}}@github.com/TasmanAnalytics/tasman_dbt_utils.git
      revision: 0.1
```

## Macro's & tests
- [Tests](#tests)
  - [test_count_distinct_matches_source](#test_count_distinct_matches_source-source)
  - [test_sum_matches_source](#test_sum_matches_source-source)
- [SQL Functions](#sql-functions)
  - [include_source](#include_source-source)
	- [include_ref](#include_ref-source)
- [Monitoring & auditing](#monitoring--auditing-source)
	- [create_table_profile](#create_table_profile-source)
- [Ops](#ops)
	- [set_warehouse_size](#set_warehouse_size-source)
	- [drop_old_relations](#drop_old_relations-source)

### Tests
#### test_count_distinct_matches_source ([source](tests/generic/test_count_distinct_matches_source.sql))

1. Count distinct of the test column (e.g. transaction_id)
2. Aggregates this by a specified field (e.g. date) to get a aggregated measure (e.g. date | count_transactions)
3. Compares this against another model (ideally with the same granularity) (e.g. date | count_transactions)
4. Returns any rows where there is a discrepancy between the aggregated measures
5. (Bonus) If you are fine with tests not being an exact match, then you can specify a threshold for which failures can occur e.g. count transactions can fluctuate within ±5% range from source

**Arguments**
* `source_model` (required): The name of the model that contains the source of truth. Specify this as a ref function e.g. `ref('raw_jaffle_shop')`.
    - These can be seed files or dbt models, so there's a degree of flexibility here  
* `source_metric` (required): The name of the column/metric sourced from `source_model`
* `comparison_field` (required): The name of the column/metric sourced from `model` in the YAML file i.e. the column/metric that is being compared against 
* `percent_mismatch_threshold` (optional, default = 0): The threshold that you would allow your tests to be out by. e.g. if you are happy with ±5% discrepancy, then set to 5. 

**Usage**
This works similarly to the off-the-box tests offered by dbt (`unique`, `not_null` etc)

1. Create the test in the YAML config, specifying values for all arguments marked as required above. Example: 
    - add any additional filtering conditions to your model via `config/where` block  

```
version: 2

models:
  - name: dmn_jaffle_shop
    description: ""
    columns:
      - name: transaction_id
        description: ""
        tests:
          - not_null
          - unique
          - count_aggregate_matches_source:
              name: count_transactions_matches_source__dmn_jaffle_shop
              source_model: ref('raw_jaffle_shop')
              source_field: sale_date
              source_metric: transaction_amount
              comparison_field: date_trunc(day, created_timestamp)
              config:
                where: date_trunc(day, created_timestamp) between '2022-01-11' and '2022-12-31' and sale_type != 'CANCELLED'
```
2. Specify a unique test name for `name`
    - If this is not specified then dbt will, by default, concatenate all the test arguments into a long list, making the whole test unreadable. 
3. Run dbt test as you normally would e.g. `dbt test -s dmn_jaffle_shop`

#### test_sum_matches_source ([source](tests/generic/test_sum_matches_source.sql))

1. Sum of the test column (e.g. revenue)
2. Aggregates this by a specified field (e.g. date) to get a aggregated measure (e.g. date | sum_revenue)
3. Compares this against another model (ideally with the same granularity) (e.g. date | sum_revenue)
4. Returns any rows where there is a discrepancy between the aggregated measures
5. (Bonus) If you are fine with tests not being an exact match, then you can specify a threshold for which failures can occur e.g. Sum revenue can fluctuate within ±5% range from source

**Arguments**
* `source_model` (required): The name of the model that contains the source of truth. Specify this as a ref function e.g. `ref('raw_jaffle_shop')`
    - These can be seed files or dbt models, so there's a degree of flexibility here
* `source_metric` (required): The name of the column/metric sourced from `source_model`
* `comparison_field` (required): The name of the column/metric sourced from `model` in the YAML file i.e. the column/metric that is being compared against 
* `percent_mismatch_threshold` (optional, default = 0): The threshold that you would allow your tests to be out by. e.g. if you are happy with ±5% discrepancy, then set to 5. 

**Usage**
This works similarly to the off-the-box tests offered by dbt (`unique`, `not_null` etc)

1. Create the test in the YAML config, specifying values for all arguments marked as required above. Example: 
    - add any additional filtering conditions to your model via `config/where` block  

```
version: 2

models:
  - name: dmn_jaffle_shop
    description: ""
    columns:
      - name: revenue
        description: ""
        tests:
          - not_null
          - sum_aggregate_matches_source:
              name: sum_revenue_matches_source__dmn_jaffle_shop
              source_model: ref('raw_jaffle_shop')
              source_field: sale_date
              source_metric: sum_revenue
              comparison_field: date_trunc(day, created_timestamp)
              config:
                where: date_trunc(day, created_timestamp) between '2022-01-11' and '2022-12-31' and sale_type != 'CANCELLED'
```
2. Specify a unique test name for `name`
    - If this is not specified then dbt will, by default, concatenate all the test arguments into a long list, making the whole test unreadable. 
3. Run dbt test as you normally would e.g. `dbt test -s dmn_jaffle_shop`

### SQL Functions
#### include_source ([source](macros/mcr_include_source.sql))
A frequently used pattern for creating initial CTEs to reference sources to create a dbt model dependancy.

| Platform  | Support |
| --------- | ------- |
| BigQuery  | ✅      |
| Snowflake | ✅      |

**Arguments**
- `source`: (required) Source model name to be used in script. This is also used to name the CTE.

**Usage**
```
    {{include_source('dbo','user')}}
    {{include_source('dbo','event')}}
```

#### include_ref ([source](macros/mcr_include_ref.sql))
A frequently used pattern for creating initial CTEs to reference upstream models to create a dbt model dependancy.

| Platform  | Support |
| --------- | ------- |
| BigQuery  | ✅      |
| Snowflake | ✅      |

**Arguments**
- `source`: (required) Source model name to be used in script. This is also used to name the CTE.
- `where_statement`: (optional) This can be used to do an initial filter on the model.

**Usage**
```
    {{include('stg_user', 'where user_active = true')}}
    {{include('dmn_pipeline')}}
```

### Monitoring & auditing
#### create_table_profile ([source](macros/create_table_profile.sql))
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
 
#### get_object_keys ([source](macros/get_object_keys.sql))
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
#### set_warehouse_size ([source](macros/set_warehouse_size.sql))
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
#### drop_old_relations ([source](macros/drop_old_relations.sql))
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
