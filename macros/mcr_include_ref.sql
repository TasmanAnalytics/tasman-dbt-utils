{#

    A frequently used pattern for creating initial CTEs to bring in models to be used in the script.

    Params:
        - source: Model name to be used in script.
                  Also used to name the CTE

    Usage:
    {{include_ref('stg_user')}}
    {{include_ref('dmn_pipeline')}}

#}

{% macro include_ref (model) %}

{{model}} as (
    select
        *
    from
        {{ref (model) }}
),

{%- endmacro %}
