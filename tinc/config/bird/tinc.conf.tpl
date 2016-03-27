protocol ospf core {
 tick 2;
 rfc1583compat yes;
 area 0.0.0.0 {
   stub no;
   networks {
{%- for network in tinc['service']['ospf']['networks'] %}
     {{ network }};
{% endfor -%}
   };
{% for interface in tinc['service']['ospf']['listen-interfaces'] %}
   interface "{{ interface }}" {
     hello 9;
     retransmit 6;
     cost 10;
     transmit delay 5;
     dead count 5;
     wait 50;
     type broadcast;
   };
{% endfor %}
   interface "*" 10.0.0.0/8, 192.168.0.0/16, 172.16.0.0/12 {
     stub;
   };
 };
};

protocol bgp {
    local as 64512;
{% for network, network_opt in tinc['network'].iteritems() -%}
{%- for node, node_opt in network_opt['node'].iteritems() -%}
    neighbor {{ local-ip }} as 64512;
{% endfor %}
{%- endfor -%}
    export all;
    import all;
    direct;
    next hop self;
}
