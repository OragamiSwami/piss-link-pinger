#!/bin/bash

links_conf=unrealircd.conf
form="html"

OPTS=$(getopt -o f: --long "format:" -- "$@")
eval set -- "$OPTS"
while true
  do
    case "$1" in
      -f|--format) form=$2; shift 2;;
      --) shift; break;;
    esac
done


function my_echo {
    class=$1
    content=$2
    if [[ "$form" == "html" ]]; then
        echo -n "<tr class=\"$class\">$content</tr>"
    elif [[ "$form" == "orig" ]]; then
        mark=""
        mark2=""
        nl=""
        case "$class" in
            "link") mark="=="; nl='\n';;
            "host") mark="++"; nl='\n';;
            "ip4"|"ip6") mark="--";mark2=" @ ";;
            "ping") nl='\n';;
        esac
        echo -ne "$mark$content$mark$mark2$nl"
    else
        echo -n $content
    fi

}

function my_time {
    ip=$1
    sport=$2
    ver=""
    if [ -z "$sport" ]; then sport=6900; fi
    if [[ "$ip" != "" ]]; then
        speed=`ping -c1 -w1 $ip |
        grep -oP "time=[^ ]* ms" | head -1`
    fi
    if [[ "$speed" != *" ms" ]]; then
        if [[ $ip =~ ":" ]]; then ver=6;fi
        speed=`sudo traceroute$ver -n -w1 -m60 -T -p $sport $ip | tail -1 | grep -oP "[0-9]+?\.[0-9]+? ms" | head -1`
    fi
    if [[ "$speed" != *" ms" ]]; then speed="failed";fi
    my_echo "ping" "$speed"
}

function my_host {
    hostname=$1
    port=$2
    if [[ "$hostname" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        ip4=$hostname
    else
        ip4=`dig a $hostname +short | grep -vP "[a-zA-Z]"|head -1`
    fi
    if [[ "$hostname" != "${1#*:[0-9a-fA-F]}" ]]; then
        ip6=$hostname
    else
        ip6=`dig aaaa $hostname +short | grep -vP "(^::|[g-zG-Z])"|head -1`
    fi
    if [ ! -z "$ip4" ]; then
        my_echo "ip4" $ip4
        my_time $ip4 $port
    fi
    if [ ! -z "$ip6" ]; then
        my_echo "ip6" ip6
        my_time $ip6 $port
    fi
}

function my_link {
    link=$1
    block=`awk "/$link/,/^}/" $links_conf | tr -d '}'`
    sport=`echo "$block" | grep port | awk '{print $2}' | tr -d '\;'`
    hostname=`echo "$block" | grep hostname | awk '{print $2}' | tr -d '\;'`
    if [ ! -z "$hostname" ]; then
        my_echo "host" $hostname
        my_host $hostname $port
    fi
    echo
}

function my_file {
    grep ^link $links_conf | awk '{print $2}' | while read link; do my_echo "link" $link; my_link $link; done
}

my_file
