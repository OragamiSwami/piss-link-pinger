#!/bin/bash

links_conf=unrealircd.conf

grep link $links_conf | awk '{print $2}' | while read link; do echo ==$link==; awk "/$link/,/^}/" frampad.conf | grep hostname | awk '{print $2}' | tr -d ';'| while read hostname; do echo ++$hostname++; dig aaaa $hostname a $hostname +short 2>/dev/null | grep -vP "(^::|[g-zG-Z])" | while read ip; do echo -n "--$ip-- @ "; [[ "$ip" != "" ]] && ping -c1 $ip | grep -oP "time=[^ ]*" || ( echo time=`sudo traceroute6 -T -p 6697 2a00:23c8:9c03:1901:5054:ff:feed:7dd7 -m60 | tail -1 | grep -oP "[0-9]+? ms" | head -1 | awk '{print $1}'` ) || echo failed ;done;echo;done; done
