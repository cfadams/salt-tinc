## salt-tinc
A salt formula for tinc

The setup works by connecting "nodes" (servers) to "introducers", which allow for all the servers to mesh.

Currently extremely experimental and still under development

## Requirements
- Tinc 1.0+
- [salt-tinc-genkeys](https://github.com/ALinuxNinja/salt-tinc-genkeys)

## Supports
- Ubuntu 14.04

CentOS support coming soon.

## Setup
1. Add the formula to the salt master via gitfs
2. Create pillar based on pillar.example
3. Create /srv/salt/secure/tinc
4. To create a network, clone [salt-tinc-genkeys](https://github.com/ALinuxNinja/salt-tinc-genkeys) to /srv/salt/secure/tinc/*network_name*
5. Create a salt-reactor to generate the certs (./gen_crt.sh *minion_name*). This can be done using events, or a salt-call while running the SLS.
