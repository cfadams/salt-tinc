mine_functions:
  tinc_externalip:
    - mine_function: grains.get
    - external_ipv4
  tinc_networks:
    - mine_function: grains.get
    - roles
