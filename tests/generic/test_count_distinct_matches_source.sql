{% test count_aggregate_matches_source(model, column_name, source_model, source_field, source_metric, comparison_field, percent_mismatch_threshold = 0) %}

{% set max_index = comparison_field|length %}

with src as (
    select
        {% for dimension in source_field %}
        {{ dimension }} as dim_{{ loop.index }},
        {% endfor %}
        sum({{ source_metric }}) as measure_src

    from {{ source_model }}
    group by
        {% for dimension in source_field %}
        {{ dimension }}{% if not loop.last %},{% endif %}
        {% endfor %}
),

new_model as (
    select
        {% for dimension in comparison_field %}
        {{ dimension }} as dim_{{ loop.index }},
        {% endfor %}
        count(distinct {{ column_name }}) as measure_comparison

    from {{ model }}

    group by
        {% for dimension in comparison_field %}
        {{ dimension }}{% if not loop.last %},{% endif %}
        {% endfor %}
),

comparison as (
    select
        {% for num in range(1, max_index + 1) %}
            coalesce(src.dim_{{ i }}, new_model.dim_{{ i }}) as dim_{{ num }},
        {% endfor %}
        src.measure_src,
        new_model.measure_comparison,
        case
        	when coalesce(src.measure_src, 0) = 0 then src.measure_src = new_model.measure_comparison
            -- for scenarios where source_value = 0 and comparison_value = 0, this will return true
        	-- for scenarios where source_value = 0 and comparison_value = ±1+, this will return false no matter the threshold
            when src.measure_src != 0 then abs(round(((new_model.measure_comparison / nullif(src.measure_src, 0)) - 1), 3)) <= ( {{ percent_mismatch_threshold }} / 100.0 )
            -- for scenarios where source_value ±1+ and comparison_value = ±1+ so the div0 function can work
            -- this will return false if the percent difference between both values are above error threshold set in yml file
        else false
        end as is_match
    from src
    full outer join new_model 
        on {% for i in range(1, max_index + 1) %} src.dim_{{ i }} = new_model.dim_{{ i }} {% if not loop.last %} and {% endif %}{% endfor %}

)

select * from comparison
where is_match = false

{% endtest %}