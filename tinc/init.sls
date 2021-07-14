{% from "tinc/map.jinja" import tinc as tinc %}
{% from "tinc/map.jinja" import roles as hosts %}

{# tinc installation #}
tinc_install:
  pkg.latest:
    - refresh: True
    - pkgs: {{ tinc['packages'] }}

{# Manage the init system #}
{% if tinc['init-system'] == 'upstart' or tinc['init-system'] == 'sysv' %}
{# upstart/sysv init #}
tinc_service_disableall:
  service.dead:
    - name: tinc
/etc/tinc/nets.boot:
  file.managed:
    - name: /etc/tinc/nets.boot
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - contents: {{ tinc['network'].keys() }}
tinc_service:
  service.running:
    - name: tinc
    - enable: True
    - require:
      - file: /etc/tinc/*
    - watch:
{% for network in tinc['network'].keys() %}
      - file: /etc/tinc/{{ network }}/*
      - file: /etc/tinc/{{ network }}/hosts/*
{% endfor %}
{% elif tinc['init-system'] == 'systemd' %}
{# systemd init #}
{% for network in tinc['network'].keys() %}
tinc_service_disableall: # systemctl stop tinc*
  service.dead:
    - name: 'tinc*'
    - enable: False
tinc_service-{{ network }}:
  service.running:
    - name: tinc@{{ network }}
    - enable: True
    - watch:
      - file: /etc/tinc/{{ network }}/*
      - file: /etc/tinc/{{ network }}/hosts/*
{% endfor %}
{% endif %}

{# Tinc Network Hosts #}
{% for network in tinc['network'].keys() %}
/etc/tinc/{{network}}:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True
/etc/tinc/{{network}}/hosts:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - clean: True
    - require:
      - file: /etc/tinc/{{ network }}
/etc/tinc/{{network}}/tinc.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents:
      - Name = {{ grains['id']|replace(".", "_")|replace("-", "_") }}
{% for option, option_value in tinc['network'][network]['node'][grains['id']]['conf']['local'].items() %}
      - {{ option }} = {{ option_value }}
{% endfor %}
    - require:
      - file: /etc/tinc/{{ network }}
/etc/tinc/{{network}}/rsa_key.priv:
  file.managed:
    - source: salt://{{tinc['keypath']}}/{{grains['id']}}/rsa_key.priv
    - user: root
    - group: root
    - mode: 400
    - require:
      - file: /etc/tinc/{{ network }}
/etc/tinc/{{network}}/rsa_key.pub:
  file.managed:
    - source: salt://{{tinc['keypath']}}/{{grains['id']}}/rsa_key.pub
    - user: root
    - group: root
    - mode: 400
    - require:
      - file: /etc/tinc/{{ network }}
{% for script, script_contents in tinc['network'][network]['node'][grains['id']]['scripts']['local'].items() %}
/etc/tinc/{{network}}/{{script}}:
  file.managed:
    - source: salt://tinc/script_template
    - user: root
    - group: root
    - mode: 700
    - template: jinja
    - context:
      script: {{ tinc['network'][network]['node'][grains['id']]['scripts']['local'] }}
      script_name: {{script}}
{% endfor %}
{% for host, host_settings in tinc['network'][network]['node'].items() %}
{% if  host != grains['id'] %}
/etc/tinc/{{network}}/tinc.conf_addhost-{{ host|replace(".", "_")|replace("-", "_") }}:
  file.append:
    - name: /etc/tinc/{{network}}/tinc.conf
    - text:
      - ConnectTo = {{ host|replace(".", "_")|replace("-", "_") }}
{% endif %}
/etc/tinc/{{network}}/hosts/{{ host|replace(".", "_")|replace("-", "_") }}:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - contents:
      - Address = {{tinc['network'][network]['node'][host]['ip']}}
{% for option, option_value in tinc['network'][network]['node'][host]['conf']['host'].items() %}
      - {{ option }} = {{ option_value }}
{% endfor %}
/etc/tinc/{{network}}/hosts/{{ host|replace(".", "_")|replace("-", "_") }}_appendkey:
  file.append:
    - name: /etc/tinc/{{network}}/hosts/{{ host|replace(".", "_")|replace("-", "_") }}
    - source: salt://{{tinc['keypath']}}/{{host}}/rsa_key.pub
{% for script, script_contents in tinc['network'][network]['node'][host]['scripts']['host'].items() %}
/etc/tinc/{{network}}/hosts/{{script}}:
  file.managed:
    - source: salt://tinc/script_template
    - user: root
    - group: root
    - mode: 700
    - template: jinja
    - context:
      script: {{ tinc['network'][network]['node'][host]['scripts']['host'][script] }}
{% endfor %}
{% endfor %}
{% else %}
/etc/tinc/{{network}}/hosts/{{ grains['id']|replace(".", "_")|replace("-", "_") }}:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - contents:
      - Address = {{tinc['network'][network]['node'][grains['id']]['ip']}}
{% for option, option_value in tinc['network'][network]['node'][grains['id']]['conf']['host'].items() %}
      - {{ option }} = {{ option_value }}
{% endfor %}
/etc/tinc/{{network}}/hosts/{{ grains['id']|replace(".", "_")|replace("-", "_") }}_appendkey:
  file.append:
    - name: /etc/tinc/{{network}}/hosts/{{ grains['id']|replace(".", "_")|replace("-", "_") }}
    - source: salt://{{tinc['keypath']}}/{{grains['id']}}/rsa_key.pub
{% for host, host_settings in hosts.items() if (network in host_settings) and (tinc['network'][network]['node'][host]['master']==True) %}
/etc/tinc/{{network}}/tinc.conf_addhost-{{ host|replace(".", "_")|replace("-", "_") }}:
  file.append:
    - name: /etc/tinc/{{network}}/tinc.conf
    - text:
      - ConnectTo = {{ host|replace(".", "_")|replace("-", "_") }}
/etc/tinc/{{network}}/hosts/{{ host|replace(".", "_")|replace("-", "_") }}:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - contents:
      - Address = {{tinc['network'][network]['node'][host]['ip']}}
{% for option, option_value in tinc['network'][network]['node'][host]['conf']['host'].items() %}
      - {{ option }} = {{ option_value }}
{% endfor %}
/etc/tinc/{{network}}/hosts/{{ host|replace(".", "_")|replace("-", "_") }}_appendkey:
  file.append:
    - name: /etc/tinc/{{network}}/hosts/{{ host|replace(".", "_")|replace("-", "_") }}
    - source: salt://{{tinc['keypath']}}/{{host}}/rsa_key.pub
{% for script, script_contents in tinc['network'][network]['node'][host]['scripts']['host'].items() %}
/etc/tinc/{{network}}/hosts/{{script}}:
  file.managed:
    - source: salt://tinc/script_template
    - user: root
    - group: root
    - mode: 700
    - template: jinja
    - context:
      script: {{ tinc['network'][network]['node'][host]['scripts']['host'][script] }}
{% endfor %}
{% endfor %}
{% endfor %}
