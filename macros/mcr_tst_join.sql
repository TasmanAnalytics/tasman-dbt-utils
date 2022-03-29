{#

    Used for TA to check whether a join will work without having to build the solution. The join will be created along with a few counts on the data.

    Params:
        - model_1: Model name of the first model to be used in the join.
        - join_criteria_1: Column name from first model which will be used as join criteria.
        - model_2: Model name of the second model to be used in the join.
        - join_criteria_2: Column name from second model which will be used as join criteria.
        - schema: Schema name that the models exist in to be able to view column names.

    Usage:
        {{mcr_test_join ('stg_user', 'user_id', 'stg_order', 'user_id', 'prod')}}

#}

{% macro mcr_test_join (model_1, join_criteria_1, model_2, join_criteria_2, schema) %}

with

model_1_counts as (
      select
          count(*) as count,
          count(distinct {{ join_criteria_1 }}) as distinct_count
      from
          {{ model_1 }}
),

model_2_counts as (
      select
          count(*) as count,
          count(distinct {{ join_criteria_2 }}) as distinct_count
      from
          {{ model_2 }}
),


test_join as (
      select
          {{mcr_get_columns (model_1, schema) }},
          {{mcr_get_columns (model_2, schema) }}
      from
          {{ model_1 }}
      left join {{ model_2 }}
      on {{ model_1 }}.{{ join_criteria_1 }} = {{ model_2 }}.{{ join_criteria_2 }}
),

join_counts as (
  select
      count(*) as count,
      count(distinct {{ join_criteria_1 }}_{{ model_1 }}) as distinct_count_1,
      count(distinct {{ join_criteria_2 }}_{{ model_2 }}) as distinct_count_2
  from
      test_join
),

counts as (
    select
        test_join.*,
        model_1_counts.count as model_1_count,
        model_1_counts.distinct_count as model_1_distinct_count,
        model_2_counts.count as model_2_count,
        model_2_counts.distinct_count as model_2_distinct_count,
        join_counts.count as join_count,
        join_counts.distinct_count_1 as distinct_join_criteria_count_1,
        join_counts.distinct_count_2 as distinct_join_criteria_count_2
    from
        test_join
    cross join
        model_1_counts
    cross join
        model_2_counts
    cross join
        join_counts
)

select * from counts

{% endmacro %}
