#!/bin/bash

cat << EOF
#
# mtproxy-install.sh
# This shell scipts will install MTProto Proxy Go v1.0.7
#
# Document
# https://github.com/9seconds/mtg
#
EOF

read -p "Please press \"y\" to continue: " answer

case $answer in
    Y|y)
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

# install mtg
wget -O /usr/local/bin/mtg-linux-amd64 https://github.com/9seconds/mtg/releases/download/v1.0.7/mtg-linux-amd64
chmod +x /usr/local/bin/mtg-linux-amd64

# generate secret
secret=$(/usr/local/bin/mtg-linux-amd64 generate-secret -c $domain tls)

# create mtproxy.service
cat > /etc/systemd/system/mtproxy.service << EOF
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
