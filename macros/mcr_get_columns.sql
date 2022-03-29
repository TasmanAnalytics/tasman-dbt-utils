{#

    Used alongside mcr_tst_join in order to find column names for models. The column names are then renamed in order to provide unquie aliases to use in the join .

    Params:
        - model: Model name which is being used in the join, this is paased automatically from mcr_tst_join.
        - schema: Schema name that the models exist in to be able to view column names.

    Usage:
    {{mcr_get_columns ('stg_users', 'prod') }}

#}

{% macro mcr_get_columns (model) %}

  {% set select_columns %}
    select
        distinct COLUMN_NAME
    from
        INFORMATION_SCHEMA.COLUMNS
    where TABLE_NAME = upper('{{model}}')
    and TABLE_SCHEMA = upper('{{schema}}')
  {% endset %}

  {% set results = run_query(select_columns) %}

  {% if execute %}
  {% set results_list = results.columns[0].values() %}
  {% else %}
  {% set results_list = [] %}
  {% endif %}



  {% for result in results_list %}

      {{ model }}.{{ result }} as {{ result }}_{{ model }}

      {%- if not loop.last -%}
      ,
      {%- endif -%}

  {%- endfor -%}

{% endmacro %}
