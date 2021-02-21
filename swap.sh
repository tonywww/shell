#!/bin/bash

cat << EOF
#
# swap.sh
# This shell scipts will create 512M SWAP file.
#
EOF

echo ""
free -h
echo ""
swapon
echo ""
echo "Before create SWAP file, make sure the SWAP file doesn't exist."

read -p "Are you sure to create 512M SWAP? [YES} " answer

case $answer in  
    YES)  
    echo "continue..."


## create SWAP
dd if=/dev/zero of=/var/swapfile bs=1024 count=524288
mkswap /var/swapfile
swapon /var/swapfile
swapon -s
chown root:root /var/swapfile
chmod 0600 /var/swapfile
echo "/var/swapfile swap swap defaults 0 0" >>/etc/fstab

free -m
echo ""
swapon
ls -lh /var/swapfile
echo ""
echo "512M SWAP file has been created!"



## go exit
    ;;  

    *)  
    echo "exit"  
    ;;  

esac  

exit 0
