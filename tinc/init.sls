{% from "tinc/map.jinja" import tinc as tinc %}
tinc_install:
{% if grains['os'] == 'Ubuntu' %}
  pkgrepo.managed:
    - ppa: {{ tinc['repo']['tinc'] }}
    - file: /etc/apt/sources.list.d/tinc.list
    - require_in:
      - pkg: tinc
{% endif %}
  pkg.latest:
    - name: tinc
    - refresh: True
{% if grains['os'] == 'Ubuntu' %}
    - pkgrepo: tinc_install
{% endif %}
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
tinc_service:
  service.running:
    - name: tinc
    - enable: True
    - watch:
{% for network,network_setting in tinc['network'].iteritems() %}
{% if network_setting['node'][grains['id']] is defined or network_setting['master'][grains['id']] is defined %}
      - file: /etc/tinc/{{ network }}/*
      - file: /etc/tinc/{{ network }}/hosts/*
{% endif %}
{% endfor %}
{% endif %}
{% if tinc['init-system'] == 'systemd' %}
{% for network,network_setting in tinc['network'].iteritems() %}
{% if network_setting['node'][grains['id']] is defined or network_setting['master'][grains['id']] is defined %}
tinc_service-{{ network }}:
  service.running:
    - name: tincd@{{ network }}
    - enable: True
    - watch:
      - file: /etc/tinc/{{ network }}/*
      - file: /etc/tinc/{{ network }}/hosts/*
{% else %}
tinc_service:
  service.disabled:
    - name: tinc@{{ network }}
{% endif %}
{% endfor %}
{% endif %}
{% for network,network_setting in tinc['network'].iteritems() %}
{% if network_setting['node'][grains['id']] is defined or network_setting['master'][grains['id']] is defined %}
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
    - source: salt://secure/tinc/{{ network }}/{{ grains['id'] }}/rsa_key.priv
    - user: root
    - group: root
    - mode: 644
tinc-{{ network }}_{{ grains['id'] }}-pubkey:
  file.managed:
    - name: /etc/tinc/{{ network }}/rsa_key.pub
    - source: salt://secure/tinc/{{ network }}/{{ grains['id'] }}/rsa_key.pub
    - user: root
    - group: root
    - mode: 644
tinc-{{ network }}_{{ grains['id'] }}-config:
  file.managed:
    - name: /etc/tinc/{{ network }}/hosts/{{ grains['id']|replace(".", "_") }}
    - source: salt://secure/tinc/{{ network }}/{{ grains['id'] }}/host
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
tinc-{{ network }}-up:
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
tinc-{{ network }}-down:
  file.managed:
    - name: /etc/tinc/{{ network }}/tinc-down
    - source: salt://tinc/config/tinc/tinc-down
    - user: root
    - group: root
    - mode: 755
{% endif %}
{% if network == "core" %}
{% for master,master_setting in tinc['network'][network]['master'] %}
tinc-{{ network }}-{{ master }}:
  file.managed:
    - name: /etc/tinc/{{ network }}/hosts/{{ master|replace(".", "_") }}
    - source: salt://secure/tinc/{{ network }}/{{ master }}/host
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - cmd: tinc-{{ network }}_cleanup
    - context:
      node: {{ master }}
{% endfor %}
{% elif tinc['network'][network]['master'][grains['id']] is defined %}
{% for node,node_setting in tinc['network'][network]['node'].iteritems() %}
tinc-{{ network }}-{{ node }}:
  file.managed:
    - name: /etc/tinc/{{ network }}/hosts/{{ node|replace(".", "_") }}
    - source: salt://secure/tinc/{{ network }}/{{ node }}/host
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
tinc-{{ network }}-{{ master|replace(".", "_") }}:
  file.managed:
    - name: /etc/tinc/{{ network }}/hosts/{{ master|replace(".", "_") }}
    - source: salt://secure/tinc/{{ network }}/{{ master }}/host
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
{% endfor %}
