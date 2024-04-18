{% test sum_aggregate_matches_source(model, column_name, source_model, source_field, source_metric, comparison_field, percent_mismatch_threshold = 0) %}

with src as (
    select
        {{ source_field }} as date,
        {{ source_metric }} as measure_src

    from {{ source_model }}
),

new_model as (
    select
        {{ comparison_field }} as date,
        sum({{ column_name }}) as measure_comparison

    from {{ model }}

    group by date
),

comparison as (
    select
        coalesce(src.date, new_model.date) as date,
        src.measure_src,
        new_model.measure_comparison,
        case
        	when src.measure_src = 0 then src.measure_src = new_model.measure_comparison
            -- for scenarios where source_value = 0 and comparison_value = 0, this will return true
        	-- for scenarios where source_value = 0 and comparison_value = ±1+, this will return false no matter the threshold
            when src.measure_src != 0 then abs(round((div0(new_model.measure_comparison, src.measure_src) - 1), 3)) <= ( {{ percent_mismatch_threshold }} / 100.0 )
            -- for scenarios where source_value ±1+ and comparison_value = ±1+ so the div0 function can work
            -- this will return false if the percent difference between both values are above error threshold set in yml file
        else false
        end as is_match
    from src
    full outer join new_model on new_model.date = src.date
)

select * from comparison
where is_match = false

{% endtest %}