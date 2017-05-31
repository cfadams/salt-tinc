{% if data['act'] == 'accept' %}
tinc_keydir:
  local.cmd.run:
    - tgt: 'salt-master-01'
    - arg:
      - mkdir -p /srv/salt/secure/{{data['id']}}
tinc_genkey:
  local.cmd.run:
    - tgt: 'salt-master-01'
    - arg:
      - openssl genpkey -algorithm RSA -out /srv/salt/secure/{{data['id']}}/rsa_key.priv 2048
      - openssl rsa -pubout -in /srv/salt/secure/{{data['id']}}/rsa_key.priv -out /srv/salt/secure/{{data['id']}}/rsa_key.pub
{% endif %}
{% if data['act'] == 'delete' %}
tinc_delkey:
  local.cmd.run:
    - tgt: 'salt-master-01'
    - arg:
      - rm -r /srv/salt/secure/{{data['id']}}
{% endif %}
