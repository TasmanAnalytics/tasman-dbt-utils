--the following parameters are used in the deduplication step of this macro
--source: cte to deduplicate
--partition_field: the field in the source file we want to deduplicate
--order_field: the timestamp field in the source file to order by (to be able to select only one row)
--order: asc (ascending) or desc (descending) determines if we want to keep the first or the last row
{#

    A frequently used pattern for deduplicating data from a cte

    Params:
        - source: cte to deduplicate
        - partition_field: field which should hold unique values to parition by
        - order_field: field used to order nonunique rows
        - order: order of order_field (ascending or descending)

    Usage:
    {{ mcr_source_deduplication(
        'cte',
        'unique_id',
        'extracted_at',
        'desc')
    }}

#}

{%
macro
    mcr_source_deduplication (
        source,
        partition_field,
        order_field,
        order
    )
%}
with
ordered as (
    select
        *,
        row_number() over (
            partition by
                {{ partition_field }}
            order by
                {{ order_field }} {{ order }}
        ) as row_number
    from
        {{ source }}
),
deduplicated as (
    select
        *
    from
        ordered
    where
        row_number = 1
)
select * from deduplicated
{% endmacro %}
