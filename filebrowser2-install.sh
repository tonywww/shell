#!/bin/bash

cat <<EOF
#
# filebrowser2-install.sh
# Support OS: Debian / Ubuntu / CentOS
#
# This shell scipts will install Filebroswer v2.
#
# For Google reCAPCHA, please have the key and secret first.
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

    ## input key & secret
    read -p "Please input listen port number(default:8081):" port
    if [ ! $port ]; then
        port=8081
    fi
    read -p "Please input your Google reCAPCHA Key: " key
    read -p "Please input your Google reCAPCHA Secret: " secret

    #check OS
    source /etc/os-release

    case $ID in
    debian | ubuntu)
        echo System OS is $PRETTY_NAME
        apt update
        no_command curl apt
        ;;

    centos | fedora | rhel | sangoma)
        echo System OS is $PRETTY_NAME
        no_command bc yum
        yumdnf="yum"
        if test "$(echo "$VERSION_ID >= 22" | bc)" -ne 0; then
            yumdnf="dnf"
        fi
        no_command curl $yumdnf
        adduser -r -d /var/www -s /sbin/nologin www-data -U
        ;;

    *)
        echo System OS is $PRETTY_NAME
        echo Unsupported system OS.
        exit 2
        ;;
    esac

    # download filebroswer
    curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

    # config init
    if [ -f "/etc/filebrowser/filebrowser.db" ]; then
        mv /etc/filebrowser/filebrowser.db /etc/filebrowser/filebrowser_backup.db
        echo "Found previous filebrowser.db, renamed to /etc/filebrowser/filebrowser_backup.db"
    else
        mkdir /etc/filebroswer
    fi
    filebrowser -d /etc/filebrowser/filebrowser.db config init
    filebrowser -d /etc/filebrowser/filebrowser.db config set --port $port \
        --baseurl "/file" \
        --root "/var/www/filebrowser/" \
        --log "/var/log/filebrowser.log" \
        --auth.method=json \
        --recaptcha.host https://recaptcha.net \
        --recaptcha.key "$key" \
        --recaptcha.secret "$secret" \
        --locale "zh-cn"

    # add user tony
    passwd=$(openssl rand -base64 6)
    filebrowser -d /etc/filebrowser/filebrowser.db users add admin $passwd --perm.admin

    mkdir -p /var/www/filebrowser/dl
    mkdir -p /var/www/filebrowser/share
    chmod -R 750 /var/www

    chown -R www-data:www-data /var/www
    chown -R www-data:www-data /etc/filebrowser

    # create systemd file and auto run
    cat >/etc/systemd/system/filebrowser.service <<EOF
[Unit]
Description=File browser v2
After=network.target

[Service]
User=www-data
Group=www-data
ExecStart=/usr/local/bin/filebrowser -d /etc/filebrowser/filebrowser.db

[Install]
WantedBy=multi-user.target

EOF

    systemctl daemon-reload
    systemctl enable filebrowser
    systemctl restart filebrowser
    systemctl status filebrowser --no-pager

    cat <<EOF
FileBrowser v2 install completed!
=======================================================================
filebroswer       : http://<your-domain.com>:$port

filebroswer path  : /usr/local/bin/filemanager
config file path  : /etc/filebroswer/filebroswer.db
=======================================================================
EOF
    echo -n "Filebrowser default username & password: "
    echo -e "\033[5;46;30m"admin $passwd"\033[0m"
    echo "(Please login http://<your-domain.com>:$port and change the password ASAP!)"
    echo ""

    ## go exit
    ;;

    ## end
*)
    echo "exit"
    ;;

esac

exit 0
