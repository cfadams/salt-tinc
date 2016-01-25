{%- for network,network_setting in tinc['network'].iteritems() -%}
{{ network }}
{% endfor -%}
