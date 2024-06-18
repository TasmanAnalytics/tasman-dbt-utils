{% macro set_warehouse_size(size) %}
	{{ return(adapter.dispatch('set_warehouse_size', 'tasman_dbt_utils')(size)) }}
{% endmacro %}

{% macro bigquery__set_warehouse_size(size) %}
    {{ exceptions.raise_compiler_error("This macro is not supported in BigQuery.") }}
{% endmacro %}

{% macro snowflake__set_warehouse_size(size) %}

	{% if var("snowflake_warehouses", None) == None %}
		{{ exceptions.raise_compiler_error("Please set the `snowflake_warehouses` variable in the dbt_project.yml.") }}
	{% endif %}

    {% set size_dict = var('snowflake_warehouses') %}
    {% set target_name = target.name %}
    
    {% if target.name in size_dict %}
        {% set env = size_dict[target_name] %}
        {% if env['size']|length == 0 %}
            {{ env['warehouse_prefix'] }}
        {% elif size in env['size'] %}
            {{ env['warehouse_prefix'] ~ size }}
        {% else %}
            {{ exceptions.raise_compiler_error("Size '" ~ size ~ "' is not valid for the environment '" ~ target_name ~ "'.") }}
        {% endif %}
    {% else %}
        {{ exceptions.raise_compiler_error("Target name '" ~ target_name ~ "' does not match any environment key.") }}
    {% endif %}

{% endmacro %}
