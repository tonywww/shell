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

read -p "Please input \"YES\" to continue: " answer

case $answer in  
    YES)  
    echo "continue..."


## make choice
read -p "Please input SWAP size (GB): [0.5/1/2/3/4] " swapsize
case $swapsize in  


## create SWAP
    if command -v fallocate >/dev/null 2>&1; then
        fallocate -l $swapsizeG /var/swapfile
    else
        dd if=/dev/zero of=/var/swapfile bs=1G count=$swapsize
    fi

mkswap /var/swapfile
swapon /var/swapfile
echo "/var/swapfile swap swap defaults 0 0" >>/etc/fstab

chmod 0600 /var/swapfile

free -m
echo ""
swapon --show
ls -lh /var/swapfile
echo ""
echo "$swapsizeG SWAP file has been created!"



## go exit
    ;;  

    *)  
    echo "exit"  
    ;;  

esac  

exit 0
