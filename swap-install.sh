#!/bin/bash

cat << EOF
#
# swap-install.sh
# This shell scipts will create custom SWAP file in /var/swapfile
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
swapsize1=$(echo $(awk 'BEGIN{print '$swapsize'*1024 }') | awk -F. '{print $1}')
    if command -v fallocate >/dev/null 2>&1; then
        fallocate -l $swapsize1\M /var/swapfile
    else
        dd if=/dev/zero of=/var/swapfile bs=1M count=$swapsize1
    fi
chmod 0600 /var/swapfile
mkswap /var/swapfile
swapon /var/swapfile
echo "/var/swapfile swap swap defaults 0 0" >>/etc/fstab

free -m
echo ""
swapon --show
ls -lh /var/swapfile
echo ""
echo $swapsize"GB SWAP file has been created!"


## go exit
    ;;  

    *)  
    echo "exit"  
    ;;  

esac  

exit 0
