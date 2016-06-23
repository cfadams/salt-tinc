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

{# upstart init #}
{% if tinc['init-system'] == 'upstart' %}
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
tinc-{{ network }}_{{ grains['id'] }}-privkey:
  file.managed:
    - name: /etc/tinc/{{ network }}/rsa_key.priv
    - source: salt://secure/tinc/{{ grains['id'] }}/rsa_key.priv
    - user: root
    - group: root
    - mode: 644
tinc-{{ network }}_{{ grains['id'] }}-pubkey:
  file.managed:
    - name: /etc/tinc/{{ network }}/rsa_key.pub
    - source: salt://secure/tinc/{{ grains['id'] }}/rsa_key.pub
    - user: root
    - group: root
    - mode: 644
tinc-{{ network }}_{{ grains['id'] }}-config:
  file.managed:
    - name: /etc/tinc/{{ network }}/hosts/{{ grains['id']|replace(".", "_")|replace("-", "_") }}
    - source: salt://secure/tinc/{{ grains['id'] }}/host
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - cmd: tinc-{{ network }}_cleanup
    - context:
      tinc: {{ tinc }}
      host: {{ grains['id'] }}
      network: {{ network }}
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
tinc-{{ network }}_down:
  file.managed:
    - name: /etc/tinc/{{ network }}/tinc-down
    - source: salt://tinc/config/tinc/tinc-down
    - user: root
    - group: root
    - mode: 755
{% if tinc['network'][network]['master'] is defined %}
{% if tinc['network'][network]['master'][grains['id']] is defined %}
{% for node,node_setting in tinc['network'][network]['node'].iteritems() %}
tinc-{{ network }}-{{ node }}:
  file.managed:
    - name: /etc/tinc/{{ network }}/hosts/{{ node|replace(".", "_")|replace("-", "_") }}
    - source: salt://secure/tinc/{{ node }}/host
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
{% endfor %}
{% elif tinc['network'][network]['node'][grains['id']] is defined %}
{% for master,master_setting in tinc['network'][network]['master'].iteritems() %}
tinc-{{ network }}_{{ master|replace(".", "_")|replace("-", "_") }}:
  file.managed:
    - name: /etc/tinc/{{ network }}/hosts/{{ master|replace(".", "_")|replace("-", "_") }}
    - source: salt://secure/tinc/{{ master }}/host
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
{% endfor %}
{% endif %}
{% else %}
{% for node,node_setting in tinc['network'][network]['node'].iteritems() %}
{% if node != grains['id'] %}
tinc-{{ network }}-{{ node }}:
  file.managed:
    - name: /etc/tinc/{{ network }}/hosts/{{ node|replace(".", "_")|replace("-", "_") }}
    - source: salt://secure/tinc/{{ node }}/host
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
{% endif %}
{% endfor %}
{% endif %}
{% endfor %}
