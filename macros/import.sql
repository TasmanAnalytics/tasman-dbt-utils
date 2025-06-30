{% macro import(import_options={}) %}
    with {{- " recursive" if import_options.get("recursive", false) }}

    {%- for key, value in kwargs.items() %}
    {%- set rel = tasman_dbt_utils._parse_import_value(value) %}
    {{ key }} as (
        select * from {{ rel.from }} {{ "where " ~ rel.where if rel.where else "" }}
    ),
    {%- endfor -%}
{% endmacro %}


{% macro _parse_import_value(import_value) %}
    {#
        Not sure how to test that a variable is an `api.Relation` since Jinja
        doesn't have `type` or `isinstance`, so just check for the `identifier`
        attribute which is (always?) present on `api.Relation` objects
    #}
    {%- if import_value.identifier -%}
        {{ return({"from": import_value}) }}
    {%- elif import_value is mapping -%}
        {% if "from" in import_value %}
            {{ return(import_value) }}
        {%- else -%}
            {{ exceptions.raise_compiler_error("tasman_dbt_utils.import received a dictionary without the 'from' key: " ~ import_value) }}
        {%- endif -%}
    {%- else -%}
        {{ exceptions.raise_compiler_error("tasman_dbt_utils.import received an unprocessable value: " ~ import_value) }}
    {%- endif -%}
{% endmacro %}
