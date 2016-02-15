log syslog { debug, trace, info, remote, warning, error, auth, fatal, bug };
router id {{pillar['tinc']['network']['core']['master'][grains['id']]['local-ip']}};
protocol kernel {
 persist;
 scan time 20;
 export all;
}
protocol device {
 scan time 10;
}

include "/etc/bird.conf.d/*.conf";
