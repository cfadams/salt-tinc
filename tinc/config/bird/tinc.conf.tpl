protocol ospf core {
 tick 2;
 rfc1583compat yes;
 area 0.0.0.0 {
   stub no;
   networks {
{% for network in tinc['service']['ospf']['networks'] %}
     {{ network }};
{% endfor %}
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
{% for interface in tinc['service']['ospf']['passive-interfaces'] %}
   interface "{{ interface }}" {
     stub;
   };
{% endfor %}
 };
};
