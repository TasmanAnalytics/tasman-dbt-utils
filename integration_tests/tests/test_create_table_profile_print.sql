{% if execute %}
  {% do tasman_dbt_utils.create_table_profile(table="data_profile") %}
{% endif %}

{# An exception will be raised from the macro which will make this test fail / not fail. #}
{% set has_passed = True %}
{% if has_passed %}
    select true limit 0
{% else %}
    select false
{% endif %}