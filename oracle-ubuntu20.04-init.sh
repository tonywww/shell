#!/bin/bash

cat <<EOF
#
# oracle-ubuntu-init.sh
#
# This shell scipts use to initial Oracle VPS Ubuntu 24.04 LTS.
# 1) set l='ls -lAhF' and ll='ls -lahF'
# 2) remove oracle-cloud-agent
# 3) remove system firewall
# 4) install softwares: nano curl axel inetutils-ping net-tools cron
# 5) set timezone to America/New_York
# 6) setup TCP BBR
# 7) set 2G SWAP
#
# THIS IS IMPORTANT! You must run the entire process as "root"!
#
EOF

# 4) disable systemd-resolved

read -p "Please press \"y\" to continue: " answer

case $answer in
Y | y)
    echo "continue..."

    # add ll and l command
    sed -i "s/\(^alias ll='ls \).*/\1-lahF'/" /root/.bashrc
    sed -i "s/\(^alias l='ls \).*/\1-lAhF'/" /root/.bashrc
    sed -i "s/\(^alias ll='ls \).*/\1-lahF'/" /home/ubuntu/.bashrc
    sed -i "s/\(^alias l='ls \).*/\1-lAhF'/" /home/ubuntu/.bashrc

    cat >>/etc/bash.bashrc <<EOF

## auto run
echo
df -h
echo
free -h

EOF

    # remove oracle-cloud-agent
    snap stop oracle-cloud-agent
    snap disable oracle-cloud-agent
    snap remove oracle-cloud-agent

    # enable all ports
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -F

    # remove firewall
    systemctl stop netfilter-persistent
    systemctl disable netfilter-persistent
    apt purge netfilter-persistent -y

    # Disable systemd-resolve as it binds to port 53 due to which Dnsmasq will be effected.
#    systemctl stop systemd-resolved
#    systemctl disable systemd-resolved

    # Also, remove the sysmlinked resolv.conf file
    # /etc/resolv.conf -> ../run/systemd/resolve/stub-resolv.conf
#    rm /etc/resolv.conf
    #Then create new resolv.conf file
#    echo "nameserver 8.8.8.8" >/etc/resolv.conf
#    echo "nameserver 1.1.1.1" >>/etc/resolv.conf

    # install tools
    apt update
    apt install -y nano curl axel inetutils-ping net-tools cron

    # change timezone
    timedatectl set-timezone America/New_York
    echo "Timezone has been changed to America/New_York."
    echo ""

    ## check and set BBR
    check_bbr_status() {
        local param=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
        if [[ x"${param}" == x"bbr" ]]; then
            return 0
        else
            return 1
        fi
    }
    if check_bbr_status; then
        echo
        echo "TCP BBR has already been enabled."
    else
        sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
        sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
        cat >>/etc/sysctl.conf <<EOF

# set TCP BBR
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

EOF
        sysctl -p
        echo "Setting TCP BBR completed..."
    fi
    # test BBR
    sysctl net.ipv4.tcp_available_congestion_control
    sysctl net.ipv4.tcp_congestion_control
    lsmod | grep bbr

    # check and set SWAP
    if [ -f "/swapfile" ]; then
        echo "/swapfile already exist!"
    else
        # create 2G SWAP
        fallocate -l 2G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo "/swapfile swap swap defaults 0 0" >>/etc/fstab
        echo "2G SWAP file has been created!"
    fi
    free -h
    swapon --show

    # go exit
    ;;

*)
    echo "exit"
    ;;

esac

exit 0
