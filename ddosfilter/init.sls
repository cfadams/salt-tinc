{% from "ddosfilter/map.jinja" import ddosfilter as ddosfilter %}
{% from "ddosfilter/map.jinja" import ddosfilter_nginx as ddosfilter_nginx %}
{% from "ddosfilter/map.jinja" import ddosfilter_varnish as ddosfilter_varnish %}
{% if pillar['ddosfilter'] is defined and pillar['ddosfilter']['frontend'] is defined and pillar['ddosfilter']['frontend'][grains['id']] is defined %}
ddosfilter-common_install:
  pkg.latest:
    - refresh: True
    - pkgs: {{ ddosfilter['packages'] }}
ddosfilter-nginx_install:
  pkgrepo.managed:
    - ppa: alinuxninja/nginx-edge
    - file: /etc/apt/sources.list.d/nginx.list
    - require_in:
      - pkg: nginx
  pkg.latest:
    - name: nginx
    - refresh: True
    - pkgrepo: ddosfilter-nginx_install
ddosfilter-nginx_service:
  service.running:
    - name: nginx
    - enable: True
ddosfilter-nginx_defaultpages:
  file.managed:
    - name: /etc/nginx/conf.d/default.conf
    - source: salt://ddosfilter/config/nginx/vhosts/default
    - user: root
    - group: root
    - template: jinja
    - context:
      ddosfilter: {{ ddosfilter }}
ddosfilter-varnish_install:
  pkgrepo.managed:
    - name: {{ ddosfilter['repo']['varnish'][ddosfilter['varnish']['version']] }}
    - file: /etc/apt/sources.list.d/varnish.list
    - key_url: {{ ddosfilter['repo']['varnish']['repokey_url'] }}
    - require_in:
      - pkg: varnish
  pkg.latest:
    - name: varnish
    - refresh: True
    - install_recommends: False
    - pkgrepo: ddosfilter-varnish_install
ddosfilter-varnish_service:
  service.running:
    - name: varnish
    - enable: True
    - file: /etc/default/varnish
    - file: /etc/varnish/default.vcl
ddosfilter-varnish_config:
  augeas.change:
    - lens: shellvars.lns
    - context: /files/etc/default/varnish
    - changes:
      - set DAEMON_OPTS '"-a localhost:80 -T localhost:6082 -f /etc/varnish/default.vcl -S /etc/varnish/secret -s malloc,{{ ddosfilter['varnish']['malloc'] }}"'
ddosfilter-tinc_network:
  file.directory:
    - name: /etc/tinc/ddosfilter/hosts
    - user: root
    - group: root
    - mode: 755
    - makedirs: True
{% endif %}
