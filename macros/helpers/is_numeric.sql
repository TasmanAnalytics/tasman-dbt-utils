{% macro is_numeric(data_type) %}

    {% set is_numeric = "int" in data_type.lower()
		or "float" in data_type.lower()
		or "decimal" in data_type.lower()
		or "numeric" in data_type.lower()
		or "double" in data_type.lower()
		or "number" in data_type.lower()
	%}

    {% do return(is_numeric) %}

{% endmacro %}