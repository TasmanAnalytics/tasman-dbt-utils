{% macro set_warehouse_size(size) %}
	{{ return(adapter.dispatch('set_warehouse_size', 'tasman_dbt_utils')(size)) }}
{% endmacro %}

{% macro snowflake__set_warehouse_size(size) %}

	{% if var("available_sizes", None) == None %}
		{{ exceptions.raise_compiler_error("Please set the `available_sizes` variable in the dbt_project.yml.") }}
	{% endif %}

    {% if size not in var("available_sizes") %}
        {{ exceptions.raise_compiler_error("Warehouse size not one of " ~ var("available_sizes")) }}
    {% endif %}

    {% if target.name == 'prod' %}
        {{ return('PROD_DBT_WH_' ~ size) }}
    {% elif target.name == 'dev' %}
        {{ return('DEV_DBT_WH_' ~ size) }}
    {% elif target.name == 'ci' %}
        {{ return('CI_WH_' ~ size) }}
    {% else %}
		{% do log('Unknown target - running with default warehouse ' ~ target.warehouse, True) %}
        {{ return(target.warehouse) }}
    {% endif %}

{% endmacro %}
