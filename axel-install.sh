#!/bin/bash

cat << EOF
#
# axel-install.sh
# Support OS: Debian / Ubuntu / CentOS
#
# This shell scipts will install axel, a download tool.
#
# Document
# https://github.com/axel-download-accelerator/axel
# https://centos.pkgs.org/7/epel-x86_64/axel-2.4-9.el7.x86_64.rpm.html
#
EOF

no_command() {
    if ! command -v $1 > /dev/null 2>&1; then
        if [ -z "$3" ]; then
        $2 install -y $1
        else
        $2 install -y $3
        fi
    fi
}

read -p "Please press \"y\" to continue: " answer

case $answer in
    Y|y)
    echo "continue..."


    if command -v axel >/dev/null 2>&1; then
        echo "axel has already installed!"
        exit 1
    fi

cd ~

#check OS
source /etc/os-release
        case $ID in
        debian|ubuntu|devuan)
        echo System OS is $PRETTY_NAME
apt update && apt install -y axel
        ;;

        centos|fedora|rhel|sangoma)
        echo System OS is $PRETTY_NAME
no_command wget yum
wget -O axel-2.4-9.el7.x86_64.rpm https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/a/axel-2.4-9.el7.x86_64.rpm
rpm -Uvh axel-2.4-9.el7.x86_64.rpm
yum install axel
        ;;
    
        esac

echo "whereis axel"
whereis axel


## go exit
    ;;

    *)
    echo "exit"
    ;;

esac

exit 0
