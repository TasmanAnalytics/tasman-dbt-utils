{% macro is_date_or_time(data_type) %}

    {% set is_datetime = "time" in data_type.lower()
		or "date" in data_type.lower()
	%}

    {% do return(is_datetime) %}

{% endmacro %}