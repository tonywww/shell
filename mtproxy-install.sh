#!/bin/bash

cat <<EOF
#
# mtproxy-install.sh
# Support OS: Debian / Ubuntu / CentOS
#
# This shell scipts will install MTProto Proxy Go latest version
#
# Document
# https://github.com/9seconds/mtg
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

read -p "Please press \"y\" to continue: " answer

case $answer in
Y | y)
    echo "continue..."

    ## input fake tls domain and port
    echo "(For example: freenom.com / bing.com / sohu.com ...)"
    read -p "Please input the fake TLS domain name(default:microsoft.com):" domain
    if [ ! $domain ]; then
        domain=mocrosoft.com
    fi
    echo "fake TLS domain="$domain

    read -p "Please input listen port number(default:443):" port
    if [ ! $port ]; then
        port=443
    fi

    #check OS
    source /etc/os-release

    case $ID in
    debian | ubuntu)
        echo System OS is $PRETTY_NAME
        apt update
        no_command wget apt
        no_command curl apt
        ;;

    centos | fedora | rhel | sangoma)
        echo System OS is $PRETTY_NAME
        no_command bc yum
        yumdnf="yum"
        if test "$(echo "$VERSION_ID >= 22" | bc)" -ne 0; then
            yumdnf="dnf"
        fi
        no_command wget $yumdnf
        no_command curl $yumdnf
        ;;

    *)
        echo System OS is $PRETTY_NAME
        echo Unsupported system OS.
        exit 2
        ;;
    esac

    # install mtg
    curl -s https://api.github.com/repos/9seconds/mtg/releases/latest |
        grep browser_download_url |
        grep mtg-linux-amd64 |
        cut -d '"' -f 4 |
        wget -O /usr/local/bin/mtg-linux-amd64 -qi -

    chmod +x /usr/local/bin/mtg-linux-amd64

    # generate secret
    secret=$(/usr/local/bin/mtg-linux-amd64 generate-secret -c $domain tls)

    # create mtproxy.service
    cat >/etc/systemd/system/mtproxy.service <<EOF
[Unit]
Description=MTProxy Go
Documentation=https://github.com/9seconds/mtg
After=network.target

[Service]
User=nobody
Type=simple
WorkingDirectory=/usr/local/bin
ExecStart=/usr/local/bin/mtg-linux-amd64 run -b 0.0.0.0:$port $secret
Restart=on-failure

[Install]
WantedBy=multi-user.target
Alias=mtg.service
EOF

    systemctl daemon-reload
    systemctl enable mtproxy.service
    systemctl restart mtproxy.service
    systemctl status mtproxy.service --no-pager -l

    echo "======================================================================="
    echo '/usr/local/bin/mtg-linux-amd64 '
    /usr/local/bin/mtg-linux-amd64 --version
    echo ""
    echo -n "Port=  "
    echo -e "\033[5;46;30m"$port"\033[0m"
    echo -n "Secret="
    echo -e "\033[5;46;30m"$secret"\033[0m"

    ## go exit
    ;;

    ## end
*)
    echo "exit"
    ;;

esac

exit 0
