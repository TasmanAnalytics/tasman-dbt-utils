# tasman_dbt_utils

# Contents
- [Installation instructions](#installation-instructions)
- [Tests](#tests)
  - [test_count_distinct_matches_source (source)](#test_count_distinct_matches_source-source)
  - [test_sum_matches_source (source)](#test_sum_matches_source-source)
# Installation instructions

# Macros

# Tests
## test_count_distinct_matches_source ([source](tests/generic/test_count_distinct_matches_source.sql))
### What it does

1. Count distinct of the test column (e.g. transaction_id)
2. Aggregates this by a specified field (e.g. date) to get a aggregated measure (e.g. date | count_transactions)
3. Compares this against another model (ideally with the same granularity) (e.g. date | count_transactions)
4. Returns any rows where there is a discrepancy between the aggregated measures
5. (Bonus) If you are fine with tests not being an exact match, then you can specify a threshold for which failures can occur e.g. count transactions can fluctuate within ±5% range from source

### Arguments
* `source_model` (required): The name of the model that contains the source of truth. Specify this as a ref function e.g. `ref('raw_jaffle_shop')`.
    - These can be seed files or dbt models, so there's a degree of flexibility here  
* `source_metric` (required): The name of the column/metric sourced from `source_model`
* `comparison_field` (required): The name of the column/metric sourced from `model` in the YAML file i.e. the column/metric that is being compared against 
* `percent_mismatch_threshold` (optional, default = 0): The threshold that you would allow your tests to be out by. e.g. if you are happy with ±5% discrepancy, then set to 5. 

### Usage
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

## test_sum_matches_source ([source](tests/generic/test_sum_matches_source.sql))
### What it does

1. Sum of the test column (e.g. revenue)
2. Aggregates this by a specified field (e.g. date) to get a aggregated measure (e.g. date | sum_revenue)
3. Compares this against another model (ideally with the same granularity) (e.g. date | sum_revenue)
4. Returns any rows where there is a discrepancy between the aggregated measures
5. (Bonus) If you are fine with tests not being an exact match, then you can specify a threshold for which failures can occur e.g. Sum revenue can fluctuate within ±5% range from source

### Arguments
* `source_model` (required): The name of the model that contains the source of truth. Specify this as a ref function e.g. `ref('raw_jaffle_shop')`
    - These can be seed files or dbt models, so there's a degree of flexibility here
* `source_metric` (required): The name of the column/metric sourced from `source_model`
* `comparison_field` (required): The name of the column/metric sourced from `model` in the YAML file i.e. the column/metric that is being compared against 
* `percent_mismatch_threshold` (optional, default = 0): The threshold that you would allow your tests to be out by. e.g. if you are happy with ±5% discrepancy, then set to 5. 

### Usage
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
