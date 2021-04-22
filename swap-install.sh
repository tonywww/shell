#!/bin/bash

cat << EOF
#
# swap.sh
# This shell scipts will create SWAP file.
#
EOF

echo ""
free -h
echo ""
swapon
echo ""

    if [ -f "/var/swapfile" ]; then
        echo "/var/swapfile already exist!"
        echo "exit..."
        exit 1
    fi

echo "Before create SWAP file, make sure the SWAP file doesn't exist."

read -p "Please input \"YES\" to continue: " answer

case $answer in  
    YES)  
    echo "continue..."


## choose swap size
read -p "Please input SWAP size (GB): [0.5/1/2/3/4] " swapsize

## create SWAP
fallocate -l $swapsize\G /var/swapfile

chmod 0600 /var/swapfile
mkswap /var/swapfile
swapon /var/swapfile
echo "/var/swapfile swap swap defaults 0 0" >>/etc/fstab

free -m
echo ""
swapon --show
ls -lh /var/swapfile
echo ""
echo $swapsize"G SWAP file has been created!"


## go exit
    ;;  

    *)  
    echo "exit"  
    ;;  

esac  

exit 0
