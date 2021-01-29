#!/bin/bash

cat << EOF

This shell will transfer a domain list to dnsmasq's format:
address=/domain.name/myip

EOF

read -p "Do you want to continue? [y/n} " answer

case $answer in
    Y|y)
    echo "continue..."


## input domain list file name
echo -e "Please input the domain list name: \c"
read list

## get IP
myip=$(curl --silent http://api.ipify.org/)

cp $list $list.backup

sed -i "s/^/address=\/&/g" $list
sed -i "s/$/&\/$myip/g" $list

cat $list

cat << EOF
File edit completed.

The backup list name is:
EOF
echo $list.backup



## go exit
    ;;

    *)
    echo "exit"
    ;;
esac
exit 0

