#!/bin/bash

cat <<EOF
#
# docker-install.sh
# Support OS: Debian / Ubuntu / CentOS
#
# This shell scipts will install Docker CE.
#
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

read -p "Please press \"y\" to continue: " answer

case $answer in
Y | y)
    echo "continue..."

    #check OS
    source /etc/os-release

    case $ID in
    debian | ubuntu)
        echo System OS is $PRETTY_NAME
        apt update
        no_command curl apt

        apt install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
        curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
        add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
        apt update
        apt install -y docker-ce
        ;;

    centos | fedora | rhel | sangoma)
        echo System OS is $PRETTY_NAME

        yum install -y yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce
        ;;
    esac

    systemctl status docker --no-pager
    echo ""

    ## go exit
    ;;

*)
    echo "exit"
    ;;
esac
exit 0
