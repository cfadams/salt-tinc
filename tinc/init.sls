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
tinc_network:
  file.directory:
    - name: /etc/tinc/core/hosts
    - user: root
    - group: root
    - mode: 755
    - makedirs: True
tinc_config:
  file.managed:
    - name: /etc/tinc/core/tinc.conf
    - source: salt://tinc/config/tinc/tinc.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
tinc_{{ grains['id'] }}-privkey:
  file.managed:
    - name: /etc/tinc/core/rsa_key.priv
    - source: salt://secure/tinc/core/{{ grains['id'] }}/rsa_key.priv
    - user: root
    - group: root
    - mode: 644
tinc_{{ grains['id'] }}-pubkey:
  file.managed:
    - name: /etc/tinc/core/rsa_key.pub
    - source: salt://secure/tinc/core/{{ grains['id'] }}/rsa_key.pub
    - user: root
    - group: root
    - mode: 644
tinc_{{ grains['id'] }}-config:
  file.managed:
    - name: /etc/tinc/core/hosts/{{ grains['id'] }}
    - source: salt://secure/tinc/core/{{ grains['id'] }}/host
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      node: {{ grains['id'] }}
tinc-up:
  file.managed:
    - name: /etc/tinc/core/tinc-up
    - source: salt://tinc/config/tinc/tinc-up
    - user: root
    - group: root
    - mode: 755
    - template: jinja
    - context:
      node: {{ grains['id'] }}
tinc-down:
  file.managed:
    - name: /etc/tinc/core/tinc-down
    - source: salt://tinc/config/tinc/tinc-down
    - user: root
    - group: root
    - mode: 755
{% for core,core_setting in pillar['tinc']['core'] %}
tinc-core-{{ core }}:
  file.managed:
    - name: /etc/tinc/core/hosts/{{ core }}
    - source: salt://secure/tinc/core/{{ core }}/host
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      node: {{ core }}
{% endfor %}
