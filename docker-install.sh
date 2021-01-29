#!/bin/bash

echo ""
echo "systemctl status docker"
systemctl status docker
echo ""
read -p "Are you sure to install Docker CE? [y/n} " answer

case $answer in
    Y|y)
    echo "continue..."

apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt-get update -y
apt-get install -y docker-ce

systemctl status docker --no-pager
echo ""


## go exit
    ;;

    *)
    echo "exit"
    ;;
esac
exit 0
