{% from "tinc/map.jinja" import tinc as tinc %}

{# Set some variables #}
{% if tinc['network']['core'] is defined %}
{% set core = True %}
{% if tinc['network']['core']['master'] is defined and tinc['network']['core']['master'][grains['id']] is defined %}
{% set nodetype = "master" %}
{% else %}
{% set nodetype = "standard" %}
{% endif %}
{% else %}
{% set core = False %}
{% set nodetype = "standard" %}
{% endif %}

{# Add tinc repo #}
tinc_repo:
{% if grains['os'] == 'Ubuntu' %}
  pkgrepo.managed:
    - ppa: {{ tinc['repo']['tinc'] }}
    - file: /etc/apt/sources.list.d/tinc.list
{% endif %}

{# tinc installation #}
tinc_install:
  pkg.latest:
    - refresh: True
    {% if nodetype == "master" %}
    - pkgs: {{tinc['packages-master']}}
    {% else %}
    - pkgs: {{tinc['packages']}}
    {% endif %}
    {% if grains['os'] == 'Ubuntu' %}
    - pkgrepo: tinc_repo
    {% endif %}
{% if tinc['init-system'] == 'upstart' %}

{# tinc networks #}
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
tinc_service:
  service.running:
    - name: tinc
    - enable: True
    - watch:
{% for network,network_setting in tinc['network'].iteritems() %}
      - file: /etc/tinc/{{ network }}/*
      - file: /etc/tinc/{{ network }}/hosts/*
{% endfor %}
{% endif %}
{% if tinc['init-system'] == 'systemd' %}
{% for network, network_setting in tinc['network'].iteritems() %}
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

{# Tinc Core Network Configuration #}
{% if core == True and nodetype == "master" %}

{# Bird Configuration #}
{% if tinc['service']['ospf'] is defined  and tinc['service']['ospf']['enabled'] == True %}
tinc_bird:
  file.managed:
    - name: /etc/bird/bird.conf
    - source: salt://tinc/config/bird/bird.conf.tpl
    - user: root
    - group: root
    - mode: 644
    - template: jinja
{% if tinc['service']['ospf']['enabled'] == True %}
  service.running:
    - name: bird
    - watch:
      - file: tinc_bird
      - file: tinc_bird-config
{% else %}
  service.disabled:
    - name: bird
{% endif %}
tinc_bird-confdir:
  file.directory:
    - name: /etc/bird.conf.d/
    - user: root
    - group: root
    - mode: 755
    - makedirs: True
tinc_bird-config:
  file.managed:
    - name: /etc/bird.conf.d/tinc.conf
    - source: salt://tinc/config/bird/tinc.conf.tpl
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      tinc: {{ tinc }}
    - require:
      - file: tinc_bird-confdir
{% endif %}
{% endif %}

{# Dnsmasq #}
tinc_dnsmasq:
  file.managed:
    - name: /etc/dnsmasq.conf
    - user: root
    - group: root
    - mode: 644
    - contents:
      - conf-dir=/etc/dnsmasq.d
  {% if tinc['service']['dns']['enabled'] == True %}
  service.running:
    - name: dnsmasq
    - enable: True
    - watch:
      - file: /etc/dnsmasq.d/*
tinc_resolv:
  file.managed:
    - name: /etc/resolv.conf
    - user: root
    - group: root
    - contents:
      - nameserver 127.0.0.1
  {% else %}
  service.dead:
    - name: dnsmasq
tinc_resolv:
  file.managed:
    - name: /etc/resolv.conf
    - user: root
    - group: root
    - contents:
      {% for nameserver in tinc['service']['dns']['external-servers'] %}
      - nameserver {{ nameserver }}
      {% endfor %}
  {% endif %}
tinc_dnsmasq-defaultdns:
  file.managed:
    - name: /etc/dnsmasq.d/tinc.conf
    - user: root
    - group: root
    - mode: 644
    - contents:
      - "### File Managed by Salt"
      - "### Management SLS: tinc"
      {% for server in tinc['service']['dns']['external-servers'] %}
      - "server=/#/{{ server }}"
      {% endfor %}
tinc_dnsmasq-hosts:
  file.managed:
    - name: /etc/dnsmasq.d/tinc_hosts.conf
    - user: root
    - group: root
    - mode: 644
    - contents:
      - "### File Managed by Salt"
      - "### Management SLS: tinc"

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
    - name: /etc/tinc/{{ network }}/hosts/{{ grains['id']|replace(".", "_")|replace("-", "_") }}
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
{% if tinc['network'][network]['master'][grains['id']] is defined %}
{% for node,node_setting in tinc['network'][network]['node'].iteritems() %}
tinc_dnsmasq-{{network}}-{{ node }}:
  file.append:
    - name: /etc/dnsmasq.d/tinc_hosts.conf
    - text:
      - "address=/{{ node }}/{{ node_setting['local-ip'] }}"
    - require_in:
      - service: tinc_dnsmasq
    - require:
      - file: tinc_dnsmasq-hosts
tinc-{{ network }}-{{ node }}:
  file.managed:
    - name: /etc/tinc/{{ network }}/hosts/{{ node|replace(".", "_")|replace("-", "_") }}
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
tinc-{{ network }}_{{ master|replace(".", "_")|replace("-", "_") }}:
  file.managed:
    - name: /etc/tinc/{{ network }}/hosts/{{ master|replace(".", "_")|replace("-", "_") }}
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
