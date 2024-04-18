{% macro include_ref (model, where_statement='') %}
{{model}} as (
    select
        *
    from
        {{ref (model) }}
        {% if where_statement|length %} {{where_statement}} {% endif %}
),
{%- endmacro %}