#!/bin/bash

echo "Do you want to add 8.8.8.8 & 1.1.1.1 DNS to this system?"
read -p "(only for GCP uses Openvpn) [y/n} " answer

case $answer in
    Y|y)
    echo "continue..."

cat >> /etc/dhcp/dhclient.conf << EOF
# for OpenVPN client dns
prepend domain-name-servers 8.8.8.8, 1.1.1.1;

EOF

service networking restart
echo "cat /etc/resolv.conf"
cat /etc/resolv.conf
echo ""
echo "Success!"
#echo "==============================================================="
#echo "Success! You need to reboot the VPS to change DNS."


## go exit
    ;;

    *)
    echo "exit"
    ;;
esac
exit 0
