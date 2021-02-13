#!/bin/bash

echo ""
#read -p "Are you sure to install EH Forwarder Bot(WeChat & QQ for Telegram)? [y/n} " answer
read -p "Are you sure to install EH Forwarder Bot(WeChat for Telegram)? [y/n} " answer

case $answer in
    Y|y)
    echo "continue..."


## input token & id
echo -e "Please input your telegram bot token: \c"
read token

echo -e "Please input your telegram user ID: \c"
read user_id


# install 
apt update -y
apt install -y make build-essential libssl-dev zlib1g-dev \
        screen libbz2-dev libreadline-dev libsqlite3-dev \
        wget curl llvm libncurses5-dev  libncursesw5-dev \
        xz-utils tk-dev ffmpeg libmagic-dev libwebp-dev

# install Python 3.6.9
cd
wget -O Python-3.6.9.tgz "https://www.python.org/ftp/python/3.6.9/Python-3.6.9.tgz"
tar -zxvf Python-3.6.9.tgz
cd Python-3.6.9
./configure
make -j8
make install

# pip3 upgrade
pip3.6 install --upgrade pip

# install EFB/ETM(EFB Telegram Master Channel)/EWS(EFB WeChat Slave Channel)
pip3 install ehforwarderbot
pip3 install efb-telegram-master
pip3 install efb-wechat-slave
#pip3 install efb-qq-slave


# create default files
mkdir -p /etc/ehforwarderbot/profiles/default/blueset.telegram
mkdir -p /etc/ehforwarderbot/profiles/default/blueset.wechat
#mkdir -p /etc/ehforwarderbot/profiles/default/milkice.qq

cat > /etc/ehforwarderbot/profiles/default/config.yaml << EOF
master_channel: blueset.telegram
slave_channels:
- blueset.wechat
#- milkice.qq
EOF

cat > /etc/ehforwarderbot/profiles/default/blueset.telegram/config.yaml << EOF
##################
# Required items #
##################

# [Bot Token]
# This is the token you obtained from @BotFather
token: "$token"

# [List of Admin User IDs]
# ETM will only process messages and commands from users
# listed below. This ID can be obtained from various ways
# on Telegram.
admins:
- $user_id
# - user_id No.2

##################
# Optional items #
##################
# [Experimental Flags]
# This section can be used to toggle experimental functionality.
# These features may be changed or removed at any time.
# Options in this section is explained afterward.
flags:
    option_one: 10
    option_two: false
    option_three: "foobar"

    send_to_last_chat: disabled

# [Network Configurations]
# [RPC Interface]
# Refer to relevant sections afterwards for details.
EOF

cat > /etc/ehforwarderbot/profiles/default/blueset.wechat/config.yaml << EOF
flags:
    delete_on_edit: true
EOF

#cat > /etc/ehforwarderbot/profiles/default/milkice.qq/config.yaml << EOF
#Client: CoolQ
#CoolQ:
#    type: HTTP
#    access_token: 6844ea40baf34eb48e76d302b2692f82
#     # keep secret, must be the same with CoolQ
#    api_root: http://172.17.0.2:5700/  # CoolQ-http-API address (remote or local)
#    host: 172.17.0.1                   # efb-qq-slave listen address
#    port: 8000                         # efb-qq-slave listen port
#    is_pro: false                      # CoolQ pro is true, otherwise is false
#    air_option:
#        upload_to_smms: true           # upload pic to sm.ms
#
#EOF

## replace radom access_token
#access_token=cat dbus-uuidgen
#sed -i "s/6844ea40baf34eb48e76d302b2692f82/$access_token/" /etc/ehforwarderbot/profiles/default/milkice.qq/config.yaml


## create /etc/systemd/system/efb.service
cat > /etc/systemd/system/efb.service << EOF
[Unit]
Description=EH Forwarder Bot instance
After=network.target
Wants=network.target
Documentation=https://github.com/blueset/ehForwarderBot

[Service]
Type=simple
Environment='EFB_PROFILE=default' 'LANG=zh_CN.UTF-8' 'PYTHONIOENCODING=utf_8' 'EFB_DATA_PATH=/etc/ehforwarderbot'
ExecStart=/usr/local/bin/ehforwarderbot --verbose --profile=${EFB_PROFILE}
Restart=on-abort
KillSignal=SIGINT
#StandardOutput=journal+file:/var/log/efb.debug
#StardardError=journal+file:/var/log/efb.error

[Install]
WantedBy=multi-user.target
Alias=efb
Alias=ehforwarderbot
EOF



#ehforwarderbot --profile=/etc/ehforwarderbot/profiles/default

# after login, press "Ctrl+C", then run the follwing commands:
#systemctl enable efb.service
systemctl restart efb.service
cat << EOF
==========================================================================
EFB will display a barcode, please use Wechat cellphone scan it to log in.
Please wait for efb-wechat starting...
==========================================================================
EOF
sleep 5s

systemctl status efb.service --no-pager
#journalctl -u efb.service -o cat



## go exit
    ;;

    *)
    echo "exit"
    ;;
esac
exit 0



# update
#pip3 install --upgrade pip
#pip3 install -U ehforwarderbot
#pip3 install -U efb-telegram-master
#pip3 install -U efb-wechat-slave
#pip3 install -U efb-qq-slave


# EFB Telegram Master help
# https://github.com/blueset/efb-telegram-master/blob/master/readme_translations/zh_CN.rst

# EFB Wechat Slave help
# https://github.com/blueset/efb-wechat-slave

# EFB QQ Slave help
# https://github.com/milkice233/efb-qq-slave/blob/master/README_zh-CN.rst
