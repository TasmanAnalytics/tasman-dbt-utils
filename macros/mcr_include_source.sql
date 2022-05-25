{#

    A frequently used pattern for creating initial CTEs to bring in sources to be used in the script.

    Params:
        - source: Source/model name to be used in script.
                  Also used to name the CTE

    Usage:
    {{include_source('dbo','user')}}
    {{include_source('dbo','event')}}

#}

{% macro include_source (schema, model) %}

{{model}} as (
    select
        *
    from
        {{ source (schema,model) }}
),

{%- endmacro %}
