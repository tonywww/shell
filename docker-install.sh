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

check_command() {
    if ! command -v $1 >/dev/null 2>&1; then
        return 0
    else
        echo "$1 has already existed. Nothing to do."
        return 1
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
        no_command lsb_release apt lsb-release

        if check_command docker; then
            apt install -y apt-transport-https ca-certificates gnupg2 software-properties-common
            curl -fsSL https://download.docker.com/linux/$ID/gpg | apt-key add -
            add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$ID $(lsb_release -cs) stable"
            apt update
            apt install -y docker-ce
        fi
        ;;

    centos | fedora | rhel | sangoma)
        echo System OS is $PRETTY_NAME

        if check_command docker; then
            yum install -y yum-utils
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            yum install -y docker-ce
            systemctl enable docker
            systemctl start docker
        fi
        ;;

    *)
        echo System OS is $PRETTY_NAME
        echo Unsupported system OS.
        exit 2
        ;;
    esac

    systemctl status docker --no-pager
    echo ""
    echo "Docker has been installed."

    ## go exit
    ;;

*)
    echo "exit"
    ;;
esac
exit 0
