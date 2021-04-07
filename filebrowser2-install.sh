#!/bin/bash

cat << EOF
#
# filebrowser2-install.sh
# This shell scipts will install Filebroswer v2.
#
# Support OS: Debian / Ubuntu / CentOS
#
# For Google reCAPCHA, please have the key and secret first.
#
EOF

read -p "Please press \"y\" to continue: " answer

case $answer in
    Y|y)
    echo "continue..."


## input key & secret
read -p "Please input your Google reCAPCHA Key: " key
read -p "Please input your Google reCAPCHA Secret: " secret


#check OS
source /etc/os-release

    case $ID in
    # debian START
    debian|ubuntu|devuan)
    echo System OS is $PRETTY_NAME

    if ! command -v curl >/dev/null 2>&1; then
       apt update && apt install curl -y
    fi
    ;;
    # debian END

    # centos START
    centos|fedora|rhel|sangoma)
    echo System OS is $PRETTY_NAME

    if ! command -v curl >/dev/null 2>&1; then
       yum install curl -y
    fi
    ;;
    # centos END
    esac

# download filebroswer
#curl -fsSL https://filebrowser.org/get.sh | bash
curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

# config init
    if [ -f "/etc/filebrowser/filebrowser.db" ]; then
        mv /etc/filebrowser/filebrowser.db /etc/filebrowser/filebrowser_backup.db
        echo "Found previous filebrowser.db, renamed to /etc/filebrowser/filebrowser_backup.db"
    else
        mkdir /etc/filebroswer
    fi
filebrowser -d /etc/filebrowser/filebrowser.db config init
filebrowser -d /etc/filebrowser/filebrowser.db config set --address 127.0.0.1 \
    --port 8081 \
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


#check OS
    case $ID in
    # debian START
    debian|ubuntu|devuan)
    echo System OS is $PRETTY_NAME
chown -R www-data:www-data /var/www
chown -R www-data:www-data /etc/filebrowser

# create systemd file and auto run
cat > /etc/systemd/system/filebrowser.service << EOF
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
    ;;
    # debian END

    # centos START
    centos|fedora|rhel|sangoma)
    echo System OS is $PRETTY_NAME
chown -R apache:apache /var/www
chown -R apache:apache /etc/filebrowser

# create systemd file and auto run
cat > /etc/systemd/system/filebrowser.service << EOF
[Unit]
Description=File browser v2
After=network.target

[Service]
User=apache
Group=apache
ExecStart=/usr/local/bin/filebrowser -d /etc/filebrowser/filebrowser.db

[Install]
WantedBy=multi-user.target

EOF
    ;;
    # centos END
    esac


systemctl daemon-reload
systemctl enable filebrowser
systemctl restart filebrowser
systemctl status filebrowser --no-pager

domain="your-domain.com"

cat << EOF
=======================================================================
Caddy v2 path        : /usr/bin/caddy
Caddyfile path       : /etc/caddy/Caddyfile
Web service          : $domain       --> /var/www/$domain
Caddy browse         : $domain/dl    --> /var/www/filebroswer/dl

filebroswer v2 path  : /usr/local/bin/filemanager
filebroswer.db path  : /etc/filebroswer/filebroswer.db

Filebrowser          : $domain/file  --> /var/www/filebroswer
# Filebrowser share  : $domain/share --> /var/www/filebroswer/share
=======================================================================
EOF
echo -n "Filebrowser default username & password: "
echo -e "\033[5;46;30m"admin $passwd"\033[0m"  
echo "(Please login http://$domain/file and change the password ASAP!)"
echo ""



## go exit
    ;;


## end    
    *)
    echo "exit"
    ;;

esac

exit 0
