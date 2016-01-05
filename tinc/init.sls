{% from "tinc/map.jinja" import tinc as tinc %}
tinc_install:
  pkgrepo.managed:
    - ppa: {{ tinc['repo']['tinc'] }}
    - file: /etc/apt/sources.list.d/tinc.list
    - require_in:
      - pkg: tinc
  pkg.latest:
    - name: tinc
    - refresh: True
    - pkgrepo: tinc_install
{% for network,network_setting in tinc['network'] %}
{% if network_setting['node'][grains['id']] is defined or network_setting['master'][grains['id']] is defined %}
tinc_network:
  file.directory:
    - name: /etc/tinc/{{ network }}/hosts
    - user: root
    - group: root
    - mode: 755
    - makedirs: True
tinc_config:
  file.managed:
    - name: /etc/tinc/{{ network }}/tinc.conf
    - source: salt://tinc/config/tinc/tinc.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      host: {{ grains['id'] }}
      network: {{ network }}
tinc_{{ grains['id'] }}-privkey:
  file.managed:
    - name: /etc/tinc/{{ network }}/rsa_key.priv
    - source: salt://secure/tinc/{{ network }}/{{ grains['id'] }}/rsa_key.priv
    - user: root
    - group: root
    - mode: 644
tinc_{{ grains['id'] }}-pubkey:
  file.managed:
    - name: /etc/tinc/{{ network }}/rsa_key.pub
    - source: salt://secure/tinc/{{ network }}/{{ grains['id'] }}/rsa_key.pub
    - user: root
    - group: root
    - mode: 644
tinc_{{ grains['id'] }}-config:
  file.managed:
    - name: /etc/tinc/{{ network }}/hosts/{{ grains['id'] }}
    - source: salt://secure/tinc/{{ network }}/{{ grains['id'] }}/host
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      node: {{ grains['id'] }}
tinc-up:
  file.managed:
    - name: /etc/tinc/{{ network }}/tinc-up
    - source: salt://tinc/config/tinc/tinc-up
    - user: root
    - group: root
    - mode: 755
    - template: jinja
    - context:
      network: {{ network }}
      node: {{ grains['id'] }}
tinc-down:
  file.managed:
    - name: /etc/tinc/{{ network }}/tinc-down
    - source: salt://tinc/config/tinc/tinc-down
    - user: root
    - group: root
    - mode: 755
{% endif %}
{% if tinc['network'][network]['master'][grains['id']] is defined %}
{% for node,node_setting in tinc['network'][network]['node'] %}
tinc-core-{{ core }}:
  file.managed:
    - name: /etc/tinc/{{ network }}/hosts/{{ node }}
    - source: salt://secure/tinc/{{ network }}/{{ node }}/host
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      node: {{ node }}
{% endfor %}
{% elif tinc['network'][network]['node'][grains['id']] is defined %}
{% for master,master_setting in tinc['network'][network]['master'] %}
tinc-core-{{ core }}:
  file.managed:
    - name: /etc/tinc/{{ network }}/hosts/{{ master }}
    - source: salt://secure/tinc/{{ network }}/{{ master }}/host
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      node: {{ master }}
{% endfor %}
{% endif %}
{% endfor %}
