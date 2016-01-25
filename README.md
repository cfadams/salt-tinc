## salt-tinc
A salt formula for tinc

The setup works by connecting "nodes" (servers) to "masters", which allow for all the servers to mesh. Nodes will be resolved via a DNS server on the "masters" to allow for name resolution. "masters" will be joined via their own tinc link, and will use OSPF to join together.

Currently extremely experimental and still under development

## Requirements
- Tinc 1.0+
- [salt-tinc-genkeys](https://github.com/ALinuxNinja/salt-tinc-genkeys)

## Supports
- Ubuntu 14.04

## Setup
1. Add the formula to the salt master via gitfs
2. Create pillar based on pillar.example
3. Create /srv/salt/secure/tinc
4. To create a network, clone [salt-tinc-genkeys](https://github.com/ALinuxNinja/salt-tinc-genkeys) to /srv/salt/secure/tinc/*network_name*
5. Create a salt-reactor to generate the certs (./gen_crt.sh *minion_name*). This can be done using events, or a salt-call while running the SLS.

## Configuration

#### tinc['internal-domains']
Type: Optional

Used to set 'internal' domains that will be resolved by the master server. Quite useful if you have setup a DNS server on the master servers to resolve the IPs of connecting servers.

#### tinc['network'][network]['subnet']
Type: Required

Used to set the subnet for the tinc network.

#### tinc['network'][network]['port']
Type: Required

Set the listening port of the tinc server/client

#### tinc['network'][network]['cipher']
Type: Future Release

Sets the cipher that tinc uses to communicate

#### tinc['network'][network]['compression']
Type: Future Release

Sets the level of compression that tinc uses to communicate

#### tinc['network'][network]['digest']
Type: Future Release

Sets the digest that tinc uses to communicate

#### tinc['service']['dns']['enabled']
Type: Optional

Enables DNS resolution for client minion names.

Sets the DNS servers used by the minion (Used with dnsmasq)

#### tinc['service']['ospf']['enabled']
Type: Future Release

Turns BIRD's OSPF on or off. Using OSPF, "introducers" on the "core" network can transfer data between subnets that may be connected to one server, but not another.

#### tinc['network'][network][master]
Type: Required

Sets & configures the minion that will be used as the master server

#### tinc['network'][network][master/node]['public-ip']
Type: Required

Sets the public ip address of the master/node

#### tinc['network'][network][master/node]['local-ip']
Type: Required

Sets the local internal tinc address of the master/node

## Notes
- The "core" network is used to link together nodes if necessary
