#!/bin/bash

cat <<EOF
#
# bbr-ls-colour-install.sh
# Support OS: Debian / Ubuntu / CentOS
#
# This shell scipts will enable TCP BBR and change ls default to colourful.
#
EOF

read -p "Please press \"y\" to continue: " answer

case $answer in
Y | y)
    echo "continue..."

    ## change vi/vim colour
    sed -i 's/\"syntax on/syntax on/' /etc/vim/vimrc

    ## change system ls colour & add l/ll
    if [ -f "/etc/bash.bashrc" ]; then
        cat >>/etc/bash.bashrc <<EOF

## change system ls colour & add l/ll
export LS_OPTIONS='--color=auto'
eval "\$(dircolors)"
alias ls='ls \$LS_OPTIONS'
alias ll='ls \$LS_OPTIONS -lahF'
alias l='ls \$LS_OPTIONS -lAhF'

## auto run
free -h

EOF
    fi

    if [ -f "/etc/bashrc" ]; then
        cat >>/etc/bashrc <<EOF

## change system ls colour & add l/ll
export LS_OPTIONS='--color=auto'
eval "\$(dircolors)"
alias ls='ls \$LS_OPTIONS'
alias ll='ls \$LS_OPTIONS -lahF'
alias l='ls \$LS_OPTIONS -lAhF'

## auto run
free -h

EOF
    fi

    cat >>~/.bashrc <<EOF

## change system ls colour & add l/ll
export LS_OPTIONS='--color=auto'
eval "\$(dircolors)"
alias ls='ls \$LS_OPTIONS'
alias ll='ls \$LS_OPTIONS -lahF'
alias l='ls \$LS_OPTIONS -lAhF'

EOF

    echo ""
    echo "The colour for ls and vim have been changed!"
    echo "You may logout and re-login to get colourful."
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

    _version_ge() {
        test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"
    }

    check_kernel_version() {
        local kernel_version=$(uname -r | cut -d- -f1)
        if _version_ge ${kernel_version} 4.9; then
            return 0
        else
            return 1
        fi
    }

    sysctl_config() {
        sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
        sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
        cat >>/etc/sysctl.conf <<EOF

# Open BBR
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

EOF

        sysctl -p >/dev/null 2>&1
    }

    if check_bbr_status; then
        echo
        echo "TCP BBR has already been enabled. nothing to do..."
        exit 0
    fi
    if check_kernel_version; then
        echo
        echo "The kernel version is greater than 4.9, directly setting TCP BBR..."
        sysctl_config
        echo "Setting TCP BBR completed..."
        echo ""
        # test BBR
        sysctl net.ipv4.tcp_available_congestion_control
        sysctl net.ipv4.tcp_congestion_control
        lsmod | grep bbr
        exit 0
    else
        echo "The kernel version is lower than 4.9, cannot set TCP BBR."
    fi

    ## go exit
    ;;

*)
    echo "exit"
    ;;

esac

exit 0
