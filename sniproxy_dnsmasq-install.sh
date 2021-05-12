#!/bin/bash

cat <<EOF
#
# sniproxy_dnsmasq-install.sh
# Support OS: Debian / Ubuntu / CentOS
#
# Please choose to install the following softwares:
#

1. install SNIProxy + DNSmasq
2. install SNIProxy only
3. install DNSmasq only
4. exit

# Before install, make sure the OpenVPN client service has been stopped!
# service openvpn-client@(client name) stop
# service openvpn-client@(client name) status

EOF

no_command() {
    if ! command -v $1 >/dev/null 2>&1; then
        if [ -z "$3" ]; then
            $2 install -y $1
        else
            $2 install -y $3
        fi
    fi
}

check_command() {
    if ! command -v $1 >/dev/null 2>&1; then
        return 0
    else
        echo "$1 has already existed. Nothing to do."
        return 1
    fi
}

## make choice
read -p "Please choose your option: [1-4]" answer
case $answer in

1 | 2 | 3)
    ## check OS
    source /etc/os-release

    case $ID in
    debian | ubuntu)
        echo System OS is $PRETTY_NAME
        apt update
        sniproxy_install=debian_build
        dnsmasq_install=debian_apt

        no_command bc apt
        no_command wget apt
        no_command curl apt
        no_command unzip apt
        no_command netstat apt net-tools
        no_command pkill apt procps
        # continue check
        ;;&

    debian)
        if test "$(echo "$VERSION_ID >= 10" | bc)" -ne 0; then
            sniproxy_install=debian_apt
        fi
        ;;

    ubuntu)
        if test "$(echo "$VERSION_ID >= 20.04" | bc)" -ne 0; then
            sniproxy_install=debian_apt
        fi
        ;;

    centos | fedora | rhel | sangoma)
        echo System OS is $PRETTY_NAME
        sniproxy_install=centos_build
        dnsmasq_install=centos_yum

        no_command bc yum
        yumdnf="yum"
        if test "$(echo "$VERSION_ID >= 22" | bc)" -ne 0; then
            yumdnf="dnf"
        fi

        no_command wget $yumdnf
        no_command curl $yumdnf
        no_command unzip $yumdnf
        no_command netstat $yumdnf net-tools
        no_command pkill $yumdnf procps-ng
        ;;

    *)
        echo System OS is $PRETTY_NAME
        echo Unsupported system OS.
        exit 2
        ;;
    esac

    ## continue check
    ;;&

    ## choose to install sniproxy
1 | 2)
    echo "continue to install SNIProxy..."

    ## read domain
    read -p "Please input your domain name: " domain
    echo "The domain is $domain"

    ## install sniproxy

    if check_command sniproxy; then
        case $sniproxy_install in
        debian_apt)
            apt install -y sniproxy
            ;;

        debian_build)
            apt install -y autotools-dev cdbs debhelper dh-autoreconf dpkg-dev gettext libev-dev libpcre3-dev libudns-dev pkg-config fakeroot devscripts build-essential

            mkdir ~/sniproxy && cd ~/sniproxy
            wget -O master.zip https://github.com/dlundquist/sniproxy/archive/master.zip
            rm -rf sniproxy-master
            unzip master.zip && cd sniproxy-master
            ./autogen.sh && dpkg-buildpackage
            sniproxy_deb=$(ls .. | grep "sniproxy_.*.deb") && echo ${sniproxy_deb}
            [[ ! -z ${sniproxy_deb} ]] && dpkg -i ../${sniproxy_deb}
            cd ~
            ;;

        centos_build)
            $yumdnf install -y autoconf automake curl gettext-devel libev-devel pcre-devel perl pkgconfig rpm-build

            yum install -y epel-release yum-utils
            yum-config-manager --enable epel
            yum install -y udns-devel

            no_command gcc $yumdnf

            mkdir ~/sniproxy && cd ~/sniproxy
            wget -O master.zip https://github.com/dlundquist/sniproxy/archive/master.zip
            rm -rf sniproxy-master
            unzip master.zip && cd sniproxy-master

            ./autogen.sh && ./configure && make dist
            rpmbuild --define "_sourcedir $(pwd)" -ba redhat/sniproxy.spec

            cd ~
            mv ~/rpmbuild/RPMS/x86_64/sniproxy-*.rpm .
            $yumdnf install -y sniproxy-0.*.x86_64.rpm
            ;;
        esac
    fi

    ## enable sniproxy autorun (old init.d mode)
    #sed -i "s/#DAEMON_ARGS=\"-c \/etc\/sniproxy.conf\"/DAEMON_ARGS=\"-c \/etc\/sniproxy.conf\"/" /etc/default/sniproxy
    #sed -i "s/ENABLED=0/ENABLED=1/" /etc/default/sniproxy

    ## create modified sniproxy.conf file
    mkdir -p /var/log/sniproxy
    if [ -f "/etc/sniproxy.conf" ]; then
        mv /etc/sniproxy.conf /etc/sniproxy_backup.conf
    fi
    cat >/etc/sniproxy.conf <<EOF
# sniproxy configuration file
# lines that start with # are comments
# lines with only white space are ignored

user nobody
#group nogroup

#user daemon

# PID file, needs to be placed in directory writable by user
pidfile /var/run/sniproxy.pid

# The DNS resolver is required for tables configured using wildcard or hostname
# targets. If no resolver is specified, the nameserver and search domain are
# loaded from /etc/resolv.conf.
resolver {
    # Specify name server
    #
    # NOTE: it is strongly recommended to use a local caching DNS server, since
    # uDNS and thus SNIProxy only uses single socket to each name server so
    # each DNS query is only protected by the 16 bit query ID and lacks
    # additional source port randomization. Additionally no caching is
    # preformed within SNIProxy, so a local resolver can improve performance.
#    nameserver 127.0.0.1
    nameserver 1.1.1.1
    nameserver 8.8.8.8

    # DNS search domain
#    search example.com

    # Specify which type of address to lookup in DNS:
    #
    # * ipv4_only   query for IPv4 addresses (default)
    # * ipv6_only   query for IPv6 addresses
    # * ipv4_first  query for both IPv4 and IPv6, use IPv4 is present
    # * ipv6_first  query for both IPv4 and IPv6, use IPv6 is present
    mode ipv4_only
}

error_log {
    # Log to the daemon syslog facility
    #syslog daemon

    # Alternatively we could log to file
    filename /var/log/sniproxy/sniproxy-error.log

    # Control the verbosity of the log
    priority notice
}

# Global access log for all listeners
access_log {
    # Same options as error_log
#    filename /var/log/sniproxy/sniproxy-access-all.log
    filename /tmp/sniproxy-access-all.log
}



# blocks are delimited with {...}
listen 80 {
    proto http
    table http_hosts

    # Enable SO_REUSEPORT to allow multiple processess to bind to this ip:port pair
    reuseport no

    # Fallback server to use if we can not parse the client request
#    fallback localhost:8080

    # Specify the source address for outgoing connections.
    #
    # Use "source client" to enable transparent proxy support. This requires
    # running sniproxy as root ("user root").
    #
    # Do not include a port in this address, otherwise you will be limited
    # to a single connection to each backend server.
    #
    # NOTE: binding to a specific address prevents the operating system from
    # selecting and source address and port optimally and may significantly
    # reduce the maximum number of simultaneous connections possible.
#    source 192.0.2.10

    # Log the content of bad requests
    #bad_requests log

    # Override global access log for this listener
    access_log {
        # Same options as error_log
#        filename /var/log/sniproxy/sniproxy-access.log
        filename /tmp/sniproxy-access.log
        priority notice
     }
}

#listen [::]:443 {
#    proto tls
    # controls if this listener will accept IPv4 connections as well on
    # supported operating systems such as Linux or FreeBSD, but not OpenBSD.
#    ipv6_v6only on
#    table https_hosts
#}

#listen 0.0.0.0 443 {
listen 443 {
    # This listener will only accept IPv4 connections since it is bound to the
    # IPv4 any address.
    proto tls
    table https_hosts

    access_log {
#        filename /var/log/sniproxy/sniproxy-access.log
        filename /tmp/sniproxy-access.log
        priority notice
    }
}

#listen 192.0.2.10:80 {
#    protocol http
#    # this will use default table
#}

#listen [2001:0db8::10]:80 {
#    protocol http
#    # this will use default table
#}

#listen unix:/var/run/proxy.sock {
#    protocol http
#    # this will use default table
#}



# named tables are defined with the table directive
table http_hosts {

#    example.com 192.0.2.10:8001
#    example.net 192.0.2.10:8002
#    example.org 192.0.2.10:8003 proxy_protocol

# Each table entry is composed of three parts:
#
# pattern:
#     valid Perl-compatible Regular Expression that matches the
#     hostname
#
# target:
#   - a DNS name
#   - an IP address and TCP port
#   - an IP address (will connect to the same port as the listener received the
#     connection)
#   - '*' to use the hostname that the client requested
#
# pattern   target
#.*\.itunes\.apple\.com$    *:443
#.* 127.0.0.1:4443


# external http port 80 to web service http port 81
$domain 127.0.0.1:81


# allows all http websites
#.* *

# Pulto TV
(.*.|)pluto.tv$ *

# pbs
(.*.|)pbs.org$ *
(.*.|)pbskids.org$ *

# Netflix
(.*.|)netflix.*$ *
(.*.|)nflximg.*$ *
(.*.|)nflxvideo.*$ *
(.*.|)nflxso.*$ *
(.*.|)nflxext.*$ *

# Hulu
(.*.|)hulu.com$ *
(.*.|)hulustream.com$ *

}



# named tables are defined with the table directive
table https_hosts {

    # When proxying to local sockets you should use different tables since the
    # local socket server most likely will not detect which protocol is being
    # used
#    example.org unix:/var/run/server.sock


# external https port 443 to web service https port 444
$domain 127.0.0.1:444


# allows all https websites
#.* *

# Pulto TV
(.*.|)pluto.tv$ *

# pbs
(.*.|)pbs.org$ *
(.*.|)pbskids.org$ *

# Netflix
(.*.|)netflix.*$ *
(.*.|)nflximg.*$ *
(.*.|)nflxvideo.*$ *
(.*.|)nflxso.*$ *
(.*.|)nflxext.*$ *

# Hulu
(.*.|)hulu.com$ *
(.*.|)hulustream.com$ *

}



# if no table specified the default 'default' table is defined
table {

    # If no port is specified the port of the incoming listener is used
#    example.com 192.0.2.10
#    example.net 192.0.2.20

}

EOF

    ## find sniproxy (user:daemon) and kill
    #pkill -u daemon -f sniproxy
    pkill -f /usr/sbin/sniproxy

    ## create sniproxy.service
    cat >/etc/systemd/system/sniproxy.service <<EOF
[Unit]
Description=SNI Proxy Service
Documentation=https://github.com/dlundquist/sniproxy
After=network.target

[Service]
Type=forking
ExecStart=/usr/sbin/sniproxy -c /etc/sniproxy.conf
#PIDFile=/var/run/sniproxy.pid

Restart=on-failure
#Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable sniproxy.service
    systemctl restart sniproxy.service

    ## continue check
    ;;&

    ## choose to install dnsmasq
1 | 3)
    echo "continue to install DNSmasq..."

    if check_command dnsmasq; then
        case $dnsmasq_install in
        debian_apt)
            apt install -y dnsmasq
            # install dig and nslookup
            no_command dig apt dnsutils
            ;;

        centos_yum)
            $yumdnf install -y dnsmasq
            # install dig and nslookup
            no_command dig $yumdnf bind-utils
            ;;
        esac
    fi

    ## disable dnsmasq modify /etc/resolv.conf
    cat >>/etc/default/dnsmasq <<EOF

# disable dnsmasq modify /etc/resolv.conf
DNSMASQ_EXCEPT=lo
#

EOF

    ## enable conf-dir
    cat >>/etc/dnsmasq.conf <<EOF

# include conf-dir
conf-dir=/etc/dnsmasq.d/,*.conf
#

EOF

    ## get my ip address
    #myip=$(curl 'https://ipapi.co/ip/')
    myip=$(curl --silent http://api.ipify.org/)

    # get internal IP for nat network VPS
    myip1=$(hostname -I)

    ## create /etc/dnsmasq.d/us-ip.conf
    cat >/etc/dnsmasq.d/us-ip.conf <<EOF
listen-address=127.0.0.1, $myip1
server=1.1.1.1
server=8.8.8.8

# Pluto TV & PBS
address=/pluto.tv/pbs.org/pbskids.org/$myip

# Netflix
address=/netflix.com/netflix.net/nflximg.com/nflximg.net/nflxvideo.com/nflxvideo.net/nflxso.com/nflxso.net/nflxext.com/nflxext.net/$myip

# Hulu
address=/hulu.com/hulustream.com/$myip

EOF

    systemctl restart dnsmasq.service

    cat <<EOF

===================================================
This VPS IP is $myip

EOF
    ## continue check
    ;;&

    ## sniproxy information
1 | 2)
    echo ""
    echo "==============================================================="
    echo "ps -ef | grep sniproxy"
    ps -ef | grep sniproxy
    echo ""

    sniproxy -V

    echo "netstat -lntup | grep caddy"
    netstat -lntup | grep caddy

    echo "netstat -lntup | grep sniproxy"
    netstat -lntup | grep sniproxy

    echo ""
    echo "sniproxy has been installed!"

    ## go exit
    ;;

*)
    echo "exit"
    ;;

esac

exit 0
