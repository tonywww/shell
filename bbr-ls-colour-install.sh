#!/bin/bash


## change Debian vi/vim colour
sed -i 's/\"syntax on/syntax on/' /etc/vim/vimrc


## change Debian ls colour & add l/ll
cat >> /etc/bash.bashrc << EOF

## change Debian system ls colour & add l/ll
export LS_OPTIONS='--color=auto'
eval \`dircolors\`
alias ls='ls \$LS_OPTIONS'
alias ll='ls \$LS_OPTIONS -l'
alias l='ls \$LS_OPTIONS -lAhF'

EOF

echo ""
echo "The colour for ls and vim has been changed!"
echo ""
echo "You may logout and re-login to get the new colour."
echo ""



## check BBR, if BBR has opened, then exit
check=$(lsmod | grep bbr)
echo "Checking system...  ${check:0:7}"
echo ""
if [ "${check:0:7}" != "tcp_bbr" ]; then 


## open BBR
lsb_release -a
uname -a

echo "=========================================================="
echo ""
#echo -e "Is linux version >=4.9.x? \c"

read -p "Is linux version >=4.9.x? [y/n]" answer

case $answer in
    Y|y)
    echo "continue..."

# install BBR
cat >> /etc/sysctl.conf << EOF

# Open BBR
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

EOF

sysctl -p

# test BBR
echo "=========================================================="
sysctl net.ipv4.tcp_available_congestion_control
echo "=========================================================="
sysctl net.ipv4.tcp_congestion_control
echo "=========================================================="
lsmod | grep bbr
echo ""

echo "BBR has installed!"  

## go exit
    ;;

    *)
    echo "exit"
    ;;
esac
exit 0


## BBR aleady installed
else
echo "BBR has aleady opened!"
echo ""

fi

