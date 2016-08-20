{% from "tinc/map.jinja" import tinc as tinc %}

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

{# upstart/sysv init #}
{% if tinc['init-system'] == 'upstart' or tinc['init-system'] == 'sysv' %}
tinc_boot:
  file.managed:
    - name: /etc/tinc/nets.boot
    - source: salt://tinc/config/tinc/nets.boot
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      tinc: {{ tinc }}

{# tinc service #}
{% if tinc['service']['tinc']['enabled'] == True %}
tinc_service:
  service.running:
    - name: tinc
    - enable: True
    - watch:
{% for network,network_setting in tinc['network'].iteritems() %}
      - file: /etc/tinc/{{ network }}/*
      - file: /etc/tinc/{{ network }}/hosts/*
{% endfor %}
{% elif tinc['service']['tinc']['enabled'] == False %}
tinc_service:
  service.dead:
    - name: tinc
    - enable: False
{% endif %}
{% endif %}

{# systemd init #}
{% if tinc['init-system'] == 'systemd' %}
tinc_service:
  service.disabled:
    - name: tinc
{% if tinc['service']['tinc']['enabled'] == True %}
{% for network, network_setting in tinc['network'].iteritems() %}
tinc_service-{{ network }}:
  service.running:
    - name: tinc@{{ network }}
    - enable: True
    - watch:
      - file: /etc/tinc/{{ network }}/*
      - file: /etc/tinc/{{ network }}/hosts/*
{% endfor %}
{% endif %}
{% endif %}

{# Tinc Network Hosts #}
{% for network,network_setting in tinc['network'].iteritems() %}
{% if network_setting['master'] is defined and network_setting['master'][grains['id']] is defined %}
{% set nodetype = "master" %}
{% else %}
{% set nodetype = "node" %}
{% endif %}
tinc-{{ network }}_network:
  file.directory:
    - name: /etc/tinc/{{ network }}/hosts
    - user: root
    - group: root
    - mode: 755
    - makedirs: True
tinc-{{ network }}_cleanup:
  cmd.run:
    - name: rm -rf /etc/tinc/{{ network }}/hosts/*
tinc-{{ network }}_config:
  file.managed:
    - name: /etc/tinc/{{ network }}/tinc.conf
    - source: salt://tinc/config/tinc/tinc.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      tinc: {{ tinc }}
      host: {{ grains['id'] }}
      network: {{ network }}
      nodetype: {{ nodetype }}
tinc-{{ network }}_{{ grains['id'] }}-privkey:
  file.managed:
    - name: /etc/tinc/{{ network }}/rsa_key.priv
    - source: {{ tinc['certpath'] }}/{{ grains['id'] }}/rsa_key.priv
    - user: root
    - group: root
    - mode: 644
tinc-{{ network }}_{{ grains['id'] }}-pubkey:
  file.managed:
    - name: /etc/tinc/{{ network }}/rsa_key.pub
    - source: {{ tinc['certpath'] }}/{{ grains['id'] }}/rsa_key.pub
    - user: root
    - group: root
    - mode: 644
tinc-{{ network }}_up:
  file.managed:
    - name: /etc/tinc/{{ network }}/tinc-up
    - source: salt://tinc/config/tinc/tinc-up
    - user: root
    - group: root
    - mode: 755
    - template: jinja
    - context:
      tinc: {{ tinc }}
      network: {{ network }}
      node: {{ grains['id'] }}
      nodetype: {{ nodetype }}
tinc-{{ network }}_down:
  file.managed:
    - name: /etc/tinc/{{ network }}/tinc-down
    - source: salt://tinc/config/tinc/tinc-down
    - user: root
    - group: root
    - mode: 755
{% if nodetype == "master" %}
{% for node,node_setting in tinc['network'][network]['node'].iteritems() %}
tinc-{{ network }}-{{ node }}:
  file.managed:
    - name: /etc/tinc/{{ network }}/hosts/{{ node|replace(".", "_")|replace("-", "_") }}
    - source: {{ tinc['certpath'] }}/{{ node }}/host
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - cmd: tinc-{{ network }}_cleanup
    - context:
      tinc: {{ tinc }}
      host: {{ node }}
      network: {{ network }}
      nodetype: node
{% endfor %}
{% for master,master_setting in tinc['network'][network]['master'].iteritems() %}
tinc-{{ network }}_{{ master|replace(".", "_")|replace("-", "_") }}:
  file.managed:
    - name: /etc/tinc/{{ network }}/hosts/{{ master|replace(".", "_")|replace("-", "_") }}
    - source: {{ tinc['certpath'] }}/{{ master }}/host
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - cmd: tinc-{{ network }}_cleanup
    - context:
      tinc: {{ tinc }}
      host: {{ master }}
      network: {{ network }}
      nodetype: master
{% endfor %}
tinc-{{ network }}_{{ grains['id'] }}-config:
  file.managed:
    - name: /etc/tinc/{{ network }}/hosts/{{ grains['id'] }}
    - source: {{ tinc['certpath'] }}/{{ grains['id'] }}/host
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - cmd: tinc-{{ network }}_cleanup
{% elif nodetype == "node" %}
{% if tinc['network'][network]['master'] is defined %}
{% for master,master_setting in tinc['network'][network]['master'].iteritems() %}
tinc-{{ network }}_{{ master|replace(".", "_")|replace("-", "_") }}:
  file.managed:
    - name: /etc/tinc/{{ network }}/hosts/{{ master|replace(".", "_")|replace("-", "_") }}
    - source: {{ tinc['certpath'] }}/{{ master }}/host
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - cmd: tinc-{{ network }}_cleanup
    - context:
      tinc: {{ tinc }}
      host: {{ master }}
      network: {{ network }}
      nodetype: master
{% endfor %}
tinc-{{ network }}_{{ grains['id'] }}-config:
  file.managed:
    - name: /etc/tinc/{{ network }}/hosts/{{ grains['id'] }}
    - source: {{ tinc['certpath'] }}/{{ grains['id'] }}/host
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - cmd: tinc-{{ network }}_cleanup
{% else %}
{% for node,node_setting in tinc['network'][network]['node'].iteritems() %}
{% if node != grains['id'] %}
tinc-{{ network }}-{{ node }}:
  file.managed:
    - name: /etc/tinc/{{ network }}/hosts/{{ node|replace(".", "_")|replace("-", "_") }}
    - source: {{ tinc['certpath'] }}/{{ node }}/host
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - cmd: tinc-{{ network }}_cleanup
    - context:
      tinc: {{ tinc }}
      host: {{ node }}
      network: {{ network }}
      nodetype: node
{% endif %}
{% endfor %}
{% endif %}
{% endif %}
{% endfor %}
