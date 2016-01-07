{%- for network,network_setting in tinc['network'].iteritems() -%}
{%- if network_setting['node'][grains['id'] is defined or network_setting['node'][grains['id']] is defined -%}
{{ network }}
{%- endif %}
{%- endfor -%}
