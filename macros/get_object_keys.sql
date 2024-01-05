{% macro get_object_keys(column, table, schema=target.schema, database=target.database) %}
    {{ return(adapter.dispatch('get_object_keys', 'tasman-dbt-utils')(column, table, database, schema)) }}
{%- endmacro %}

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
		{%- set table_scan_result = run_query(object_keys_query) -%}
	{% endif %}

	{% do table_scan_result.print_table(max_rows=50, max_column_width=200) %}

{% endmacro %}
