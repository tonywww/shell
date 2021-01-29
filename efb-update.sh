#!/bin/bash

#pip3 show ehforwarderbot
#pip3 show efb-telegram-master
#pip3 show efb-wechat-slave
#pip3 show efb-qq-slave

echo  "The current versions are:"
pip3 list | grep -E "efb-|ehforwarderbot"
echo ""
echo "PLease wait me to search..."
pip3 list -o | grep -E "efb-|ehforwarderbot"
echo ""
echo "The above are the new versions:"
echo ""
read -p "Are you sure to update EH Forwarder Bot(WeChat & QQ for Telegram)？ [y/n} " answer

case $answer in
    Y|y)
    echo "continue..."

systemctl stop efb
pip3 install --upgrade pip
pip3 install -U ehforwarderbot
pip3 install -U efb-telegram-master
pip3 install -U efb-wechat-slave
pip3 install -U efb-qq-slave
systemctl start efb
systemctl status efb --no-pager

## go exit
    ;;

    *)
    echo "exit"
    ;;
esac
exit 0
