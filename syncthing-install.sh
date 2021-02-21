#!/bin/bash

cat << EOF
#
# syncthing-install.sh
# This shell scipts will install Syncthing as a service.
#
#
EOF

read -p "Please press \"y\" to continue: " answer

case $answer in
    Y|y)
    echo "continue..."


# Add the release PGP keys:
    if ! command -v curl >/dev/null 2>&1; then
       apt update -y && apt install curl -y
    fi
curl -s https://syncthing.net/release-key.txt | apt-key add -

# Add the "stable" channel to your APT sources:
echo "deb https://apt.syncthing.net/ syncthing stable" | tee /etc/apt/sources.list.d/syncthing.list


# Update and install syncthing:
apt install apt-transport-https -y
apt update -y
apt install syncthing -y

# create syncthing user
useradd -m syncthing

systemctl enable syncthing@syncthing.service
systemctl restart syncthing@syncthing.service

echo "Please wait for Syncthing service starting..."
sleep 5s

systemctl status syncthing@syncthing.service --no-pager



## go exit
    ;;

    *)
    echo "exit"
    ;;

esac

exit 0
