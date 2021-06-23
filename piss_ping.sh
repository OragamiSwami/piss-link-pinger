#!/bin/bash

links_conf=frampad.conf
form="html"
ipv6_enable=`ip addr | grep inet6 &>/dev/null; echo $?`

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
        bound=""
        tr="<td class=\"$class\">"
        end="</td>"
        case "$class" in
            "link") bound="<tr>";;
            "host") ;;
            "ip4"|"ip6") ;;
            "end") tr=""; end="</tr>\n";;
        esac
        echo -ne "$bound$tr$content$end"
    elif [[ "$form" == "orig" ]]; then
        mark=""
        mark2=""
        nl=""
        case "$class" in
            "link") mark="=="; nl='\n';;
            "host") mark="++"; nl='\n';;
            "ip4"|"ip6") mark="--";mark2=" @ ";;
            #"ping") nl='\n';;
            "end") nl='\n';;
        esac
        echo -ne "$bound$mark$content$mark$mark2$bound$nl"
    else
        echo -n $content
    fi

}

function my_ports {
    ip=$1
    ports="6667 6668 6666 6669 6665 6670 6664"
    for port in $ports; do
        nc -Czw1 $ip $port &>/dev/null && my_echo "port" "$port open" && break
    done
    ports="6697 6698 6696 6699 6695 6700 6694"
    for port in $ports; do
        nc -Czw1 $ip $port &>/dev/null && my_echo "port" "$port open" && break
    done
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
    sport=$2
    if [[ "$hostname" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        ip4=$hostname
    else
        ip4=`dig a $hostname +short | grep -vP "[a-zA-Z]"|head -1`
    fi
    if [[ ! "$ipv6_enable" ]]; then
        if [[ "$hostname" != "${1#*:[0-9a-fA-F]}" ]]; then
            ip6=$hostname
        else
            ip6=`dig aaaa $hostname +short | grep -vP "(^::|[g-zG-Z])"|head -1`
        fi
    fi
    if [ ! -z "$ip4" ]; then
        my_echo "ip4" $ip4
        my_ports $ip4
        my_time $ip4 $sport
    fi
    if [ ! -z "$ip6" ]; then
        my_echo "ip6" $ip6
        my_ports $ip6
        my_time $ip6 $sport
    fi
}

function my_link {
    link=$1
    block=`awk "/$link/,/^}/" $links_conf | tr -d '}'`
    sport=`echo "$block" | grep port | awk '{print $2}' | tr -d '\;'`
    hostname=`echo "$block" | grep hostname | awk '{print $2}' | tr -d '\;'`
    if [ ! -z "$hostname" ]; then
        my_echo "host" $hostname
        my_host $hostname $sport
    fi
    my_echo "end" ""
}

function my_file {
    grep ^link $links_conf | awk '{print $2}' | while read link; do my_echo "link" $link; my_link $link; done
}

if [[ "$form" == "html" ]]; then
    echo -ne "<html>\n<body><h1>`date`</h1>\n<table>\n"
fi

my_file

if [[ "$form" == "html" ]]; then
   echo -ne "</table>\n</body>\n</html>\n"
fi

