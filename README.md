[![tasman_logo][tasman_wordmark_black]][tasman_website_light_mode]
[![tasman_logo][tasman_wordmark_cream]][tasman_website_dark_mode]

---

_We are the boutique analytics consultancy that turns disorganised data into real business value. [Get in touch][tasman_contact] to learn more about how Tasman can help solve your organisations data challenges._

# tasman_dbt_utils

## What is tasman_dbt_utils?

`tasman_dbt_utils` is a dbt package with reusable macro's. It includes macro's for, but not limited to:

-   tests
-   monitoring & auditing
-   SQL functions
-   ops functions

The intention for this package is to have each macro available for [dbt-snowflake](https://github.com/dbt-labs/dbt-snowflake) and [dbt-bigquery](https://github.com/dbt-labs/dbt-bigquery). Some functions will be only available for one of the platforms because of the fundamental differences between them. For example managing warehouse-size's is only a thing in Snowflake. This package does not intend to replace other packages which are commonly used such as [dbt-utils](https://github.com/dbt-labs/dbt-utils) or [dbt-expectations](https://github.com/calogica/dbt-expectations). This package add's functionalities which those package's don't provide.

## Installation

```
packages:
    - git: "https://github.com/TasmanAnalytics/tasman_dbt_utils.git"
      revision: 1.2.2
```

## Macro's & tests

-   [tasman_dbt_utils](#tasman_dbt_utils)
    -   [What is tasman_dbt_utils?](#what-is-tasman_dbt_utils)
    -   [Installation](#installation)
    -   [Macro's \& tests](#macros--tests)
        -   [Tests](#tests)
            -   [test_count_distinct_matches_source (source)](#test_count_distinct_matches_source-source)
            -   [test_sum_matches_source (source)](#test_sum_matches_source-source)
        -   [SQL Functions](#sql-functions)
            -   [include_source (source)](#include_source-source)
            -   [include_ref (source)](#include_ref-source)
        -   [Monitoring \& auditing](#monitoring--auditing)
            -   [create_table_profile (source)](#create_table_profile-source)
            -   [get_object_keys (source)](#get_object_keys-source)
        -   [Ops](#ops)
            -   [set_warehouse_size (source)](#set_warehouse_size-source)
            -   [drop_old_relations (source)](#drop_old_relations-source)

### Tests

#### test_count_distinct_matches_source ([source](tests/generic/test_count_distinct_matches_source.sql))

1. Count distinct of the test column (e.g. transaction_id)
2. Aggregates this by a specified field (e.g. date) to get a aggregated measure (e.g. date | count_transactions)
3. Compares this against another model (ideally with the same granularity) (e.g. date | count_transactions)
4. Returns any rows where there is a discrepancy between the aggregated measures
5. (Bonus) If you are fine with tests not being an exact match, then you can specify a threshold for which failures can occur e.g. count transactions can fluctuate within ±5% range from source

**Arguments**

-   `source_model` (required): The name of the model that contains the source of truth. Specify this as a ref function e.g. `ref('raw_jaffle_shop')`.
    -   These can be seed files or dbt models, so there's a degree of flexibility here
-   `source_metric` (required): The name of the column/metric sourced from `source_model`
-   `comparison_field` (required): The name of the column/metric sourced from `model` in the YAML file i.e. the column/metric that is being compared against
-   `percent_mismatch_threshold` (optional, default = 0): The threshold that you would allow your tests to be out by. e.g. if you are happy with ±5% discrepancy, then set to 5.

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

-   `source_model` (required): The name of the model that contains the source of truth. Specify this as a ref function e.g. `ref('raw_jaffle_shop')`
    -   These can be seed files or dbt models, so there's a degree of flexibility here
-   `source_metric` (required): The name of the column/metric sourced from `source_model`
-   `comparison_field` (required): The name of the column/metric sourced from `model` in the YAML file i.e. the column/metric that is being compared against
-   `percent_mismatch_threshold` (optional, default = 0): The threshold that you would allow your tests to be out by. e.g. if you are happy with ±5% discrepancy, then set to 5.

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

#### import ([source](macros/import.sql))

Expand key-value pairs into CTEs.

The CTE names will be the key, and the values will be used in the `FROM` clause. There is a special named parameter, `import_options`, which can be used to pass options to the macro.

The value can either be a relation, or a dictionary with the following structure:

```
{
    "from": <relation>,
    "where": <where_clause>
}
```

**Arguments**

- `**kwargs`: (required) Key-value pairs to use as CTEs.
- `import_options`: (optional) A dictionary of options to pass to the import macro. The supported options are:
  - `recursive`: (optional) Whether to include the `recursive` keyword after `with`. Defaults to `false`.

**Usage**

```
-- Simple usage
{{ tasman_dbt_utils.import(
  orders=source("orders"),
  customers=ref("customers")
) }}

-- Advanced usage (dict value, import options)
{{ tasman_dbt_utils.import(
  orders=source("orders"),
  customers={"from": ref("customers"), "where": "is_active = true"},
  import_options={
      "recursive": true
  }
) }}
```

#### include_source ([source](macros/mcr_include_source.sql))

A frequently used pattern for creating initial CTEs to reference sources to create a dbt model dependancy.

| Platform  | Support |
| --------- | ------- |
| BigQuery  | ✅      |
| Snowflake | ✅      |

**Arguments**

-   `source`: (required) Source model name to be used in script. This is also used to name the CTE.

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

-   `source`: (required) Source model name to be used in script. This is also used to name the CTE.
-   `where_statement`: (optional) This can be used to do an initial filter on the model.

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

-   `table`: the name of the table it should do the table scan on.
-   `schema` (optional, default=target.schema): the schema of where the target table is located.
-   `database` (optional, default=target.database): the database of where the target table is located.

#### get_object_keys ([source](macros/get_object_keys.sql))

Gets all of the object keys (including nested keys) of a column and prints them to the terminal.

| Platform  | Support |
| --------- | ------- |
| BigQuery  | ❌      |
| Snowflake | ✅      |

_Scope: model, snapshot_

**Argements**

-   `column`: the name of the object column.
-   `table`: the name of the target table.
-   `schema` (optional, default=target.schema): the schema of where the target table is located.
-   `database` (optional, default=target.database): the database of where the target table is located.

### Ops

#### set_warehouse_size ([source](macros/set_warehouse_size.sql))

Sets a custom warehouse size for individual models.

| Platform  | Support |
| --------- | ------- |
| BigQuery  | ❌      |
| Snowflake | ✅      |

_Scope: model, snapshot_

**Arguments**

-   `size` (required): the size of the warehouse

**Usage**

```
{{
    config(
        snowflake_warehouse=tasman_dbt_utils.set_warehouse('M')
    )
}}
```

This requires a dict of environment, warehouses and the available warehouse size's to be set in the dbt_project.yml. If the environment is missing from `dbt_project.yml` it uses the default warehouse.

```
vars:
  tasman_dbt_utils:
    snowflake_warehouses:
      prod:
        warehouse_prefix: "PROD_WH_"
        size: ["XS", "S", "M"]
      ci:
        warehouse_prefix: "CI_WH_"
        size: ["XS", "S", "M"]
```

#### drop_old_relations ([source](macros/drop_old_relations.sql))

This macro takes the relations in the manifest and compares it to the tables and views in the warehouse. Tables and views which are in the warehouse but not in the manifest will be dropped.

| Platform  | Support |
| --------- | ------- |
| BigQuery  | ❌      |
| Snowflake | ✅      |

_Scope: model, seed, snapshot_

**Arguments**

-   `schema_prefix` (optional, default=target.schema): the prefix of the schema's where the relations should be deleted.
-   `database` (optional, default=target.database): the database where the relations should be deleted.
-   `dry_run` (optional, default=True): when set to True it will print the statements, when set to False it will actually remove the relations.

**Usage**

```
dbt run-operation drop_old_relations --args '{dry_run: False, schema: dbt}'
```

## Contributing

### Integration tests

Configure your credentials by making a copy of the `.env.example` file called `.env` and fill in the required values.

If you're using `direnv`, run `direnv allow` to automatically load the environment variables; otherwise load them manually, for example:

```shell
set -a; source .env; set +a
```

Run the integration tests with:

```shell
make integration_tests
```


[tasman_website_dark_mode]: https://tasman.ai?utm_source=github&utm_medium=internal-referral&utm_campaign=tasman-dbt-utils#gh-dark-mode-only
[tasman_website_light_mode]: https://tasman.ai?utm_source=github&utm_medium=internal-referral&utm_campaign=tasman-dbt-utilst#gh-light-mode-only
[tasman_contact]: https://tasman.ai/contact?utm_source=github&utm_medium=internal-referral&utm_campaign=tasman-dbt-utils
[tasman_wordmark_cream]: https://raw.githubusercontent.com/TasmanAnalytics/.github/master/images/tasman_wordmark_cream_500.png#gh-dark-mode-only
[tasman_wordmark_black]: https://raw.githubusercontent.com/TasmanAnalytics/.github/master/images/tasman_wordmark_black_500.png#gh-light-mode-only
