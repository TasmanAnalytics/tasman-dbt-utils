{#

    A frequently used pattern for creating initial CTEs to bring in sources to be used in the script.

    Params:
        - source: Source/model name to be used in script.
                  Also used to name the CTE
        - where_statement: Can be used to do an initial filter on the model.

    Usage:
    {{include('stg_user', 'where user_active = true')}}
    {{include('dmn_pipeline')}}

#}

{% macro include_ref (model, where_statement='') %}
{{model}} as (
    select
        *
    from
        {{ref (model) }}
        {% if where_statement|length %} {{where_statement}} {% endif %}
),
{%- endmacro %}