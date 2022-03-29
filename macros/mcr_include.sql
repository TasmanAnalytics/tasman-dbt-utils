{#

    A frequently used pattern for creating initial CTEs to bring in sources/models to be used in the script.

    Params:
        - source: Source/model name to be used in script.
                  Also used to name the CTE

    Usage:
    {{include('stg_user')}}
    {{include('dmn_pipeline')}}

#}

{% macro include (source) %}

{{source}} as (
    select
        *
    from
        {{ref (source) }}
),

{%- endmacro %}
