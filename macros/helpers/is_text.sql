{% macro is_text(data_type) %}

    {% set is_text = "string" in data_type.lower()
		or 'text' in data_type.lower()
		or 'char' in data_type.lower()
	%}

    {% do return(is_text) %}

{% endmacro %}