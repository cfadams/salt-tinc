{% if data['act'] == 'accept' %}
tinc_keydir:
  local.cmd.run:
    - tgt: 'salt-master'
    - arg:
      - mkdir -p /srv/keys/{{data['id']}} && openssl genpkey -algorithm RSA -out /srv/keys/{{data['id']}}/rsa_key.priv 2048 && openssl rsa -pubout -in /srv/keys/{{data['id']}}/rsa_key.priv -out /srv/keys/{{data['id']}}/rsa_key.pub
{% elif data['act'] == 'delete' %}
tinc_delkey:
  local.cmd.run:
    - tgt: 'salt-master'
    - arg:
      - rm -r /srv/keys/{{data['id']}}
{% endif %}
