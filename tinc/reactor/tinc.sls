{% if data['act'] == 'accept' %}
tinc_keydir:
  local.cmd.run:
    - tgt: 'salt-master'
    - arg:
      - mkdir -p /srv/salt/secure/tinc/{{data['id']}} && openssl genpkey -algorithm RSA -out /srv/salt/secure/tinc/{{data['id']}}/rsa_key.priv 2048 && openssl rsa -pubout -in /srv/salt/secure/tinc/{{data['id']}}/rsa_key.priv -out /srv/salt/secure/tinc/{{data['id']}}/rsa_key.pub
{% elif data['act'] == 'delete' %}
tinc_delkey:
  local.cmd.run:
    - tgt: 'salt-master'
    - arg:
      - rm -r /srv/keys/{{data['id']}}
{% endif %}
