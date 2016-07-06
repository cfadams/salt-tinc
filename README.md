## salt-tinc
A salt formula for tinc

The setup works by connecting "nodes" (servers) to "masters", which allow for all the servers to mesh. Nodes will be resolved via a DNS server on the "masters" to allow for name resolution. "masters" will be joined via their own tinc link, and will use OSPF to join together.

Currently extremely experimental and still under development

## Requirements

* Tinc 1.0+
* [salt-tinc-genkeys](https://github.com/ALinuxNinja/salt-tinc-genkeys)

## Supports

* Ubuntu 16.04
* Ubuntu 14.04
* Centos 7
* Centos 6

## Setup
1. Fork the repository
2. Add the formula to the salt master via gitfs
3. Create pillar based on pillar.example
4. Create /srv/salt/secure/tinc
5. To create a network, clone [salt-tinc-genkeys](https://github.com/ALinuxNinja/salt-tinc-genkeys) to /srv/salt/secure/tinc
6. Create a salt-reactor to generate the certs (Example: reactor.sls)
