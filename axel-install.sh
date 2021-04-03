#!/bin/bash

cat << EOF
#
# axel-install.sh
# This shell scipts will install axel, a download tool.
#
# Support OS: Debian / Ubuntu / CentOS
#
# Document
# https://github.com/axel-download-accelerator/axel
# https://centos.pkgs.org/7/epel-x86_64/axel-2.4-9.el7.x86_64.rpm.html
#
EOF

read -p "Please press \"y\" to continue: " answer

case $answer in
    Y|y)
    echo "continue..."


cd ~

#check OS
source /etc/os-release
    case $ID in

    # debian START
    debian|ubuntu|devuan)
    echo System OS is $PRETTY_NAME
    if command -v axel >/dev/null 2>&1; then
        echo "axel has already installed!"
        exit 1
    fi
apt update && apt install -y axel
    ;;
    # debian END

    # centos START
    centos|fedora|rhel|sangoma)
    echo System OS is $PRETTY_NAME
    if command -v axel >/dev/null 2>&1; then
        echo "axel has already installed!"
        exit 1
    fi
wget -O axel-2.4-9.el7.x86_64.rpm https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/a/axel-2.4-9.el7.x86_64.rpm
rpm -Uvh axel-2.4-9.el7.x86_64.rpm
yum install axel
    ;;
    # centos END
    
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
