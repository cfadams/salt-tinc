## salt-tinc
A salt formula for [tinc](http://tinc-vpn.org)

The setup works by creating a full VPN mesh between configured nodes. Also supports configuration by adding nodes to 'master nodes' which allow for tinc to be meshed by adding keys to the 'master nodes'

Currently experimental, test before using

## Requirements

* Supported Linux Distribution (See Below)
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
