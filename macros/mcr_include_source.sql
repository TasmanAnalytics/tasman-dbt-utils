{% macro include_source (schema, model) %}

{{model}} as (
    select
        *
    from
        {{ source (schema,model) }}
),

{%- endmacro %}
