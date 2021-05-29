#!/bin/bash

cat <<EOF
#
# efb-wechat-install.sh
# Support OS: Debian / Ubuntu / CentOS
#
# This shell scipts will install EH Forwarder Bot WeChat for Telegram.
#

1. install EH Forwarder Bot Wechat + Python3
2. install EH Forwarder Bot Wechat + Docker (Docker version)
3. exit

# EH Forwarder Bot help
# https://ehforwarderbot.readthedocs.io/zh_CN/latest/
# EFB Telegram Master help
# https://github.com/blueset/efb-telegram-master/blob/master/readme_translations/zh_CN.rst
# EFB Wechat Slave help
# https://github.com/blueset/efb-wechat-slave
# EFB QQ Slave help
# https://github.com/milkice233/efb-qq-slave/blob/master/README_zh-CN.rst
#
EOF

no_command() {
    if ! command -v $1 >/dev/null 2>&1; then
        if [ -z "$3" ]; then
            $2 install -y $1
        else
            $2 install -y $3
        fi
    fi
}

check_command() {
    if ! command -v $1 >/dev/null 2>&1; then
        return 0
    else
        echo "$1 has already existed. Nothing to do."
        return 1
    fi
}

## check OS
source /etc/os-release

## make choice
read -p "Please choose your option: [1-3]" answer
case $answer in

1 | 2)
    # get token & id
    while true; do
        read -p "Please input your telegram bot token: " token
        read -p "Please input your telegram user ID: " user_id
        if [ -z "$token" ] || [ -z "$user_id" ]; then
            cat <<EOF
Both telegram bot token and user ID are required.
Please try again, or press Ctrl+C to break and exit.

EOF
            continue
        fi
        break
    done

    # create default EFB config files
    mkdir -p /etc/ehforwarderbot/profiles/default/blueset.telegram
    mkdir /etc/ehforwarderbot/profiles/default/blueset.wechat
    #mkdir /etc/ehforwarderbot/profiles/default/milkice.qq

    cat >/etc/ehforwarderbot/profiles/default/config.yaml <<EOF
master_channel: blueset.telegram
slave_channels:
- blueset.wechat
#- milkice.qq
EOF

    cat >/etc/ehforwarderbot/profiles/default/blueset.telegram/config.yaml <<EOF
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
    send_to_last_chat: disabled

# [Network Configurations]
# [RPC Interface]
# Refer to relevant sections afterwards for details.
EOF

    cat >/etc/ehforwarderbot/profiles/default/blueset.wechat/config.yaml <<EOF
flags:
    delete_on_edit: true
EOF

    ## generate UUID for coolq-token
    #coolq-token=$(cat /proc/sys/kernel/random/uuid | sed 's/-//g')
    #
    #cat > /etc/ehforwarderbot/profiles/default/milkice.qq/config.yaml << EOF
    #Client: CoolQ
    #CoolQ:
    #    type: HTTP
    #    access_token: $coolq-token
    #     # keep secret, must be the same with CoolQ
    #    api_root: http://172.17.0.2:5700/  # CoolQ-http-API address (remote or local)
    #    host: 172.17.0.1                   # efb-qq-slave listen address
    #    port: 8000                         # efb-qq-slave listen port
    #    is_pro: false                      # CoolQ pro is true, otherwise is false
    #    air_option:
    #        upload_to_smms: true           # upload pic to sm.ms
    #
    #EOF

    chmod -R 757 /etc/ehforwarderbot
    # # continue check
    ;;&

1)
    case $ID in
    debian | ubuntu)
        echo System OS is $PRETTY_NAME
        apt update
        python_install=debian_build

        no_command bc apt
        no_command wget apt
        no_command curl apt
        no_command tar apt
        # continue check
        ;;&

    debian)
        if test "$(echo "$VERSION_ID >= 10" | bc)" -ne 0; then
            python_install=debian_apt
        fi
        ;;

    ubuntu)
        if test "$(echo "$VERSION_ID >= 18.04" | bc)" -ne 0; then
            python_install=debian_apt
        fi
        ;;

    centos | fedora | rhel | sangoma)
        echo System OS is $PRETTY_NAME
        python_install=centos_build

        no_command bc yum
        yumdnf="yum"
        if test "$(echo "$VERSION_ID >= 22" | bc)" -ne 0; then
            yumdnf="dnf"
        fi

        no_command wget $yumdnf
        no_command curl $yumdnf
        no_command tar $yumdnf
        ;;

    *)
        echo System OS is $PRETTY_NAME
        echo Unsupported system OS.
        exit 2
        ;;
    esac

    ## install python3
    case $python_install in
    debian_apt)
        apt install -y python3 python3-pip python3-pil
        # efb wechat dependencies
        apt install -y ffmpeg libmagic-dev libwebp-dev
        ;;

    debian_build)
        apt install -y make build-essential libssl-dev zlib1g-dev \
            libbz2-dev libreadline-dev libsqlite3-dev \
            llvm libncurses5-dev libncursesw5-dev \
            xz-utils tk-dev
        # efb wechat dependencies
        apt install -y ffmpeg libmagic-dev libwebp-dev

        cd ~
        wget -O Python-3.9.5.tgz "https://www.python.org/ftp/python/3.9.5/Python-3.9.5.tgz"
        tar -zxvf Python-3.9.5.tgz
        rm Python-3.9.5.tgz
        cd Python-3.9.5
        ./configure --enable-optimizations
        make -j8 && make install
        ;;

    centos_build)
        $yumdnf install -y make gcc openssl-devel bzip2-devel libffi-devel sqlite-devel
        # efb wechat dependencies
        $yumdnf install -y file-devel libwebp-tools
        yum install -y epel-release
        rpm -v --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
        rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
        yum install -y ffmpeg

        cd ~
        wget -O Python-3.9.5.tgz "https://www.python.org/ftp/python/3.9.5/Python-3.9.5.tgz"
        tar -zxvf Python-3.9.5.tgz
        rm Python-3.9.5.tgz
        cd Python-3.9.5
        ./configure
        make -j8 && make install
        ;;
    esac

    # install EFB/ETM(EFB Telegram Master Channel)/EWS(EFB WeChat Slave Channel)
    pip3 install ehforwarderbot
    pip3 install efb-telegram-master
    pip3 install efb-wechat-slave
    #pip3 install efb-qq-slave

    ## create /etc/systemd/system/efb.service
    cat >/etc/systemd/system/efb.service <<EOF
[Unit]
Description=EH Forwarder Bot instance
After=network.target
Wants=network.target
Documentation=https://github.com/blueset/ehForwarderBot

[Service]
User=nobody
#CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
#AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
#NoNewPrivileges=true

Type=simple
Environment='EFB_PROFILE=default' 'LANG=zh_CN.UTF-8' 'PYTHONIOENCODING=utf_8' 'EFB_DATA_PATH=/etc/ehforwarderbot'
ExecStart=/usr/local/bin/ehforwarderbot --verbose --profile=${EFB_PROFILE}
Restart=on-abort
KillSignal=SIGINT
StandardOutput=journal
StardardError=journal

[Install]
WantedBy=multi-user.target
Alias=ehforwarderbot.service
EOF

    systemctl daemon-reload
    systemctl enable efb.service
    systemctl start efb.service

    cat <<EOF
====================================================================================
EFB will display a barcode, please use Wechat in your cellphone to scan it to log in.
Please wait 8s for efb-wechat starting...

journalctl -u efb.service -o cat --no-pager -n 50
====================================================================================
EOF
    sleep 8s
    journalctl -u efb.service -o cat --no-pager -n 50
    ;;

2)
    case $ID in
    debian | ubuntu)
        echo System OS is $PRETTY_NAME
        apt update
        no_command curl apt
        no_command lsb_release apt lsb-release

        if check_command docker; then
            apt install -y apt-transport-https ca-certificates gnupg2 software-properties-common
            curl -fsSL https://download.docker.com/linux/$ID/gpg | apt-key add -
            add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$ID $(lsb_release -cs) stable"
            apt update
            apt install -y docker-ce
        fi
        ;;

    centos | fedora | rhel | sangoma)
        echo System OS is $PRETTY_NAME

        if check_command docker; then
            yum install -y yum-utils
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            yum install -y docker-ce
            systemctl enable docker
            systemctl start docker
        fi
        ;;

    *)
        echo System OS is $PRETTY_NAME
        echo Unsupported system OS.
        exit 2
        ;;
    esac

    #docker pull jemyzhang/ehforwarderbot
    #docker run -d -v /etc/localtime:/etc/localtime \
    #    -v /etc/ehforwarderbot:/data \
    #    --name efb --restart always jemyzhang/ehforwarderbot

    docker pull mikubill/efbwechat
    docker run -d -v /etc/localtime:/etc/localtime \
        -v /etc/ehforwarderbot:/opt/app/ehforwarderbot \
        -e EFB_DATA_PATH=/opt/app/ehforwarderbot \
        -e LANG=zh_CN.UTF-8 -e PYTHONIOENCODING=utf_8 \
        --name efb --restart always mikubill/efbwechat

    cat <<EOF
====================================================================================
EFB will display a barcode, please use Wechat in your cellphone to scan it to log in.
Please wait 8s for efb-wechat starting...

docker logs efb
====================================================================================
EOF
    sleep 8s
    docker logs efb
    ;;

\
    *)
    echo "exit"
    ;;

esac

exit 0
