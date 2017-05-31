{% from "tinc/map.jinja" import tinc as tinc %}
{% from "tinc/map.jinja" import mine_data as mine_data %}
{% from "tinc/map.jinja" import mine_data_externalip as mine_data_externalip %}

{# Add tinc repo #}
tinc_repo:
{% if grains['os'] == 'Ubuntu' %}
  pkgrepo.managed:
    - humanname: Tinc-VPN
    - name: deb {{ tinc['repo']['tinc']['url'] }}
    - file: /etc/apt/sources.list.d/tinc.list
    - key_url: {{ tinc['repo']['tinc']['key'] }}
{% elif grains['os'] == 'Debian' %}
  pkgrepo.managed:
    - humanname: Tinc VPN
    - name: deb {{ tinc['repo']['tinc']['url'] }}
    - file: /etc/apt/sources.list.d/tinc.list
    - key_url: {{ tinc['repo']['tinc']['key'] }}
{% elif grains['os'] == 'CentOS' %}
  file.managed:
    - name: /etc/yum.repos.d/tinc.repo
    - source: {{ tinc['repo']['tinc']['url'] }}
    - source_hash: sha512={ tinc['repo']['tinc']['hash'] }}
{% endif %}

{# tinc installation #}
tinc_install:
  pkg.latest:
    - refresh: True
    - pkgs: {{ tinc['packages'] }}
    - pkgrepo: tinc_repo

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
    - contents: {{ mine_data[grains['id']] }}
tinc_service:
  service.running:
    - name: tinc
    - enable: True
    - watch:
{% for network in mine_data[grains['id']] %}
      - file: /etc/tinc/{{ network }}/*
      - file: /etc/tinc/{{ network }}/hosts/*
{% endfor %}
{% elif tinc['init-system'] == 'systemd' %}
{# systemd init #}
{% for network in mine_data[grains['id']] %}
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
{% for network in mine_data[grains['id']] %}
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
/etc/tinc/{{network}}/tinc.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents:
      - Name = {{grains['id']}}
      {% set config_local = salt['pillar.get']('tinc:network:'~network~':conf:local') %}
      {% set config_local_final = salt['pillar.get']('tinc:network:'~network~':node:'~grains['id']~':conf:local',default=config_local,merge=True).items() %}
      {% for option, option_value in config_local_final %}
      - {{ option }} = {{ option_value }}
      {% endfor %}
{% if tinc['network'][network]['type']=="central" %}
{% if tinc['network'][network]['node'][grains['id']] is defined and tinc['network'][network]['node'][grains['id']]['master']==True %}
{% for host, host_settings in mine_data.iteritems() if (network in host_settings) and (host != grains['id']) %}
{% if tinc['network'][network]['node'] is defined and tinc['network'][network]['node'][host] is defined and tinc['network'][network]['node'][host]['conf'] is defined and tinc['network'][network]['node'][host]['conf']['host'] is defined %}
{% set config_host = salt['pillar.get']('tinc:network:'~network~':conf:host') %}
{% set config_host_final = salt['pillar.get']('tinc:network:'~network~':node:'~host~':conf:host',default=config_host,merge=True).items() %}
{% else %}
{% set config_host_final = salt['pillar.get']('tinc:network:'~network~':conf:host').items() %}
{% endif %}
/etc/tinc/{{network}}/tinc.conf_addhost-{{ host|replace(".", "_")|replace("-", "_") }}:
  file.append:
    - name: /etc/tinc/{{network}}/tinc.conf
    - text:
      - ConnectTo = {{ host|replace(".", "_")|replace("-", "_") }}
/etc/tinc/{{network}}/hosts/{{ host|replace(".", "_")|replace("-", "_") }}:
  file.managed:
    - source: {{ tinc['certpath'] }}/{{ host }}/host
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      config: {{config_host_final}}
      public_ip: {{mine_data_externalip[host]}}
{% endfor %}
{% else %}
{% for host, host_settings in mine_data.iteritems() if (network in host_settings) and (tinc['network'][network]['node'][host] is defined) and (tinc['network'][network]['node'][host]['master'] is defined) and (tinc['network'][network]['node'][host]['master']==True) %}
{% if tinc['network'][network]['node'] is defined and tinc['network'][network]['node'][host] is defined and tinc['network'][network]['node'][host]['conf'] is defined and tinc['network'][network]['node'][host]['conf']['host'] is defined %}
{% set config_host = salt['pillar.get']('tinc:network:'~network~':conf:host') %}
{% set config_host_final = salt['pillar.get']('tinc:network:'~network~':node:'~host~':conf:host',default=config_host,merge=True).items() %}
{% else %}
{% set config_host_final = salt['pillar.get']('tinc:network:'~network~':conf:host').items() %}
{% endif %}
/etc/tinc/{{network}}/tinc.conf_addhost-{{ host|replace(".", "_")|replace("-", "_") }}:
  file.append:
    - name: /etc/tinc/{{network}}/tinc.conf
    - text:
      - ConnectTo = {{ host|replace(".", "_")|replace("-", "_") }}
/etc/tinc/{{network}}/hosts/{{ host|replace(".", "_")|replace("-", "_") }}:
  file.managed:
    - source: {{ tinc['certpath'] }}/{{ host }}/host
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      config: {{ config_host_final }}
{% endfor %}
{% endif %}
{% endif %}
{% endfor %}
