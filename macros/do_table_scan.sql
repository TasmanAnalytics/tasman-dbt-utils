{% macro do_table_scan(table, schema=target.schema, database=target.database) %}
	{{ return(adapter.dispatch('do_table_scan', 'tasman-dbt-utils')(table, schema, database)) }}
{%- endmacro %}

{% macro default__do_table_scan(table, schema=target.schema, database=target.database) %}

	{%- set metrics_list = ['count', 'count_distinct', 'null_count', 'min', 'max', 'range', 'avg', 'top_count'] -%}
	
	{% set information_schema_query %}

		select

			TABLE_CATALOG as DATABASE_NAME,
			TABLE_SCHEMA as SCHEMA_NAME,
			TABLE_NAME,
			COLUMN_NAME,
			ORDINAL_POSITION,
			DATA_TYPE

		from 
			{% if target.type == 'bigquery' %}
				{{ database }}.{{ schema }}.INFORMATION_SCHEMA.COLUMNS
			{% elif target.type == 'snowflake' %}
				{{ database }}.INFORMATION_SCHEMA.COLUMNS
			{% endif %}
		where lower(table_schema) = lower('{{ schema }}')
			and lower(table_name) = lower('{{ table }}')

	{% endset %}

	{% if execute %}
		{%- set information_schema_result = dbt_utils.get_query_results_as_dict(information_schema_query) -%}
	{% endif %}

	{% set table_scan_query %}

		with table_scan as (
		{%- for column_name in information_schema_result.COLUMN_NAME -%}
			select 
				'{{ information_schema_result.DATABASE_NAME[loop.index0] }}' as database_name,
				'{{ information_schema_result.SCHEMA_NAME[loop.index0] }}' as schema_name,
				'{{ information_schema_result.TABLE_NAME[loop.index0] }}' as table_name,
				'{{ information_schema_result.COLUMN_NAME[loop.index0] }}' as column_name,
				cast('{{ information_schema_result.ORDINAL_POSITION[loop.index0] }}' as {{ dbt.type_int() }}) as ordinal_position,
				cast(count(*) as {{ dbt.type_int() }}) as row_count,
				cast(count(distinct {{ information_schema_result.COLUMN_NAME[loop.index0] }}) as {{ dbt.type_int() }}) as distinct_count,
				cast(sum(case when {{ information_schema_result.COLUMN_NAME[loop.index0] }} is null then 1 else 0 end) as {{ dbt.type_int() }}) as null_count,
				count(*) = count(distinct {{ information_schema_result.COLUMN_NAME[loop.index0] }}) as is_unique,


				{% if is_numeric(information_schema_result.DATA_TYPE[loop.index0].lower())
					or is_date_or_time(information_schema_result.DATA_TYPE[loop.index0].lower()) %}
					cast(max({{ information_schema_result.COLUMN_NAME[loop.index0] }}) as {{ dbt.type_string() }}) as max,
					cast(min({{ information_schema_result.COLUMN_NAME[loop.index0] }}) as {{ dbt.type_string() }}) as min,
				{% else %}
					cast(null as {{ dbt.type_string() }}) as max,
					cast(null as {{ dbt.type_string() }}) as min,
				{% endif %}

				{% if is_numeric(information_schema_result.DATA_TYPE[loop.index0].lower()) %}
					cast(avg({{ information_schema_result.COLUMN_NAME[loop.index0] }}) as {{ dbt.type_numeric() }}) as avg
				{% else %}
					cast(null as {{ dbt.type_numeric() }}) as avg
				{% endif %}
		
			from {{ database }}.{{ schema }}.{{ table }}
			group by 1,2,3,4,5

			{% if not loop.last %}
			union all
			{% endif %}

		{% endfor %}
		)

		select * from table_scan
		order by ordinal_position

	{% endset %}

	{% if execute %}
		{%- set table_scan_result = run_query(table_scan_query) -%}
	{% endif %}

	{% do table_scan_result.print_table(max_columns=20) %}

{% endmacro %}