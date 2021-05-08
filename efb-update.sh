#!/bin/bash

cat <<EOF
#
# efb-update.sh
# Support OS: Debian / Ubuntu / CentOS
#
# This shell scipts will update EH Forwarder Bot (WeChat for Telegram).
#
EOF

echo "The current versions are:"
pip3 list | grep -E "efb-|ehforwarderbot"
echo ""
echo "Seaching new versions..."
pip3 list -o | grep -E "efb-|ehforwarderbot"
echo ""
echo "The above are the newer versions."
echo ""

read -p "Please press \"y\" to continue update: " answer

case $answer in
Y | y)
    echo "continue..."

    echo "Stopping efb.service. Please wait... "
    systemctl stop efb
    pip3 install -U ehforwarderbot
    pip3 install -U efb-telegram-master
    pip3 install -U efb-wechat-slave
    #pip3 install -U efb-qq-slave
    systemctl start efb
    systemctl status efb --no-pager

    ## go exit
    ;;

*)
    echo "exit"
    ;;

esac

exit 0
