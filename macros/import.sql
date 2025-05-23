{% macro import(import_options={}) %}
    with {{- " recursive" if import_options.get("recursive", false) }}

    {%- for key, value in kwargs.items() %}
    {{ key }} as (
        select * from {{ value }}
    ),
    {%- endfor -%}
{% endmacro %}
