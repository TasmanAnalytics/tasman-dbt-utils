{% macro get_object_keys(column, table, schema=target.schema, database=target.database) %}
    {{ return(adapter.dispatch('get_object_keys', 'tasman_dbt_utils')(column, table, database, schema)) }}
{%- endmacro %}

{% macro default__get_object_keys(size) %}
    {{ exceptions.raise_compiler_error("This macro is not supported for the adapter that is currently being used.") }}
{% endmacro %}

{% macro snowflake__get_object_keys(column, table, schema=target.schema, database=target.database) %}

	{% set object_keys_query %}
		select 
			object.key, 
			regexp_replace(object.path, '\\[[0-9]+\\]', '[]') as path,
			typeof(object.value) as data_type, 
			count(*) as total_count
		from {{ database }}.{{ schema }}.{{ table }},
		lateral flatten(input=>{{ column }}, recursive=>true) object
		group by all 
		order by total_count desc
	{% endset %}

	{% if execute %}
		{%- set query_result = run_query(object_keys_query) -%}
	{% endif %}

	{% do query_result.print_table(max_rows=50, max_column_width=200) %}

{% endmacro %}
