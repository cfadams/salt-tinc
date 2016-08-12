{% if data['act'] == 'accept' %}
tinc_genkey:
  local.cmd.run:
    - tgt: 'salt-master-01'
    - arg: 
      - /srv/salt/secure/tinc/gen_crt.sh {{ data['id'] }}
{% endif %}
