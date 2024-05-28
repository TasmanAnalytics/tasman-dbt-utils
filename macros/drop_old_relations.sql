{% macro drop_old_relations(schema_prefix=target.schema, database=target.database, dry_run=True) %}
	{{ return(adapter.dispatch('drop_old_relations', 'tasman_dbt_utils')(schema_prefix, database, dry_run)) }}
{%- endmacro %}

{% macro bigquery__drop_old_relations(size) %}
    {{ exceptions.raise_compiler_error("This macro is not supported in BigQuery.") }}
{% endmacro %}

{% macro snowflake__drop_old_relations(schema_prefix=target.schema, database=target.database, dry_run=True) %}
	{# Get the models that currently exist in dbt #}
	{% if execute %}
	{% set current_models=[] %}

	{% for node in graph.nodes.values()
		| selectattr("resource_type", "in", ["model", "seed", "snapshot"])%}
			{% do current_models.append(node.name) %}
		
	{% endfor %}
	{% endif %}

	{# Run a query to create the drop statements for all relations in Snowflake that are NOT in the dbt project #}
	{% set cleanup_query %}

		with models_to_drop as (
			select
				case 
					when lower(table_type) = 'base table' then 'table'
					when lower(table_type) = 'view' then 'view'
				end as relation_type,
				concat_ws('.', table_catalog, table_schema, table_name) as relation_name
			from {{ database }}.information_schema.tables
			where upper(table_schema) ilike '{{ schema_prefix.upper() }}%'
				and upper(table_name) not in
				({%- for model in current_models -%}
					'{{ model.upper() }}'
					{%- if not loop.last -%}
						,
					{% endif %}
				{%- endfor -%})) 

		select 'drop ' || relation_type || ' ' || relation_name || ';' as drop_commands
		from models_to_drop

	{% endset %}

	{% set drop_commands = run_query(cleanup_query).columns[0].values() %}

	{# Execute each of the drop commands for each relation #}
	{% if drop_commands %}
		{% if dry_run | as_bool == False %}
			{% do log('Executing DROP commands...', True) %}
		{% else %}
			{% do log('Printing DROP commands...', True) %}
		{% endif %}
		
		{% for drop_command in drop_commands %}
			{% do log(drop_command, True) %}
			{% if dry_run | as_bool == False %}
			{% do run_query(drop_command) %}
			{% endif %}
		{% endfor %}
	{% else %}
		{% do log('No relations to clean.', True) %}
	{% endif %}

{%- endmacro -%}