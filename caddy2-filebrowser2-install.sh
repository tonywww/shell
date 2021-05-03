#!/bin/bash

cat << EOF
#
# caddy2-filebrowser2-install.sh
# Support OS: Debian / Ubuntu / CentOS
#
# This shell scipts will install Caddy v2 & Filebroswer v2.
#
# Before the installation, please make sure your domain has pointed to this VPS's IP."
# For Google reCAPCHA, please have the key and secret first."
#
EOF

no_command() {
    if ! command -v $1 > /dev/null 2>&1; then
        if [ -z "$3" ]; then
        $2 install -y $1
        else
        $2 install -y $3
        fi
    fi
}

read -p "Please press \"y\" to continue: " answer

case $answer in
    Y|y)
    echo "continue..."


#### install Caddy2

## input domain
read -p "Please input your domain name (without www.): " domain
read -p "Please input your Google reCAPCHA Site Key: " key
read -p "Please input your Google reCAPCHA Secret Key: " secret


# check previous caddy v1 service
    if [ -f "/etc/systemd/system/caddy.service" ]; then
        systemctl stop caddy.service
        systemctl disable caddy.service
        rm /etc/systemd/system/caddy.service
        systemctl daemon-reload
        echo "Found previous Caddy v1 service, removed Caddy v1 service."
    fi


#check OS
source /etc/os-release
        case $ID in
        debian|ubuntu|devuan)
        echo System OS is $PRETTY_NAME
apt update
no_command curl apt

## download Caddy2
apt install -y debian-keyring debian-archive-keyring apt-transport-https
#curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/cfg/gpg/gpg.155B6D79CA56EA34.key' | apt-key add -
#curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/cfg/setup/config.deb.txt?distro=debian&version=any-version' | tee -a /etc/apt/sources.list.d/caddy-stable.list
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | apt-key add -
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee -a /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install caddy -y
        ;;

        centos|fedora|rhel|sangoma)
        echo System OS is $PRETTY_NAME
        no_command bc yum
        yumdnf="yum"
        if test "$(echo "$VERSION_ID >= 22" | bc)" -ne 0; then
            yumdnf="dnf"
        fi
no_command curl $yumdnf

$yumdnf -y install yum-plugin-copr
$yumdnf -y copr enable @caddy/caddy
$yumdnf -y install caddy
        ;;
        esac


## create /etc/caddy/Caddyfile
cat > /etc/caddy/Caddyfile << EOF
# The Caddyfile is an easy way to configure your Caddy web server.
#
# Unless the file starts with a global options block, the first
# uncommented line is always the address of your site.
#
# To use your own domain name (with automatic HTTPS), first make
# sure your domain's A/AAAA DNS records are properly pointed to
# this machine's public IP, then replace the line below with your
# domain name.


# Global options
    {
# set defalut CA to ZeroSSL
        acme_ca https://acme.zerossl.com/v2/DV90
        email   admin@$domain
# work with sniproxy change port
#        http_port  81
#        https_port 444
# auto https off
#        auto_https off
# auto http redirect to https off
#        auto_https disable_redirects
    }


## $domain config START

#http://$domain, https://$domain {
$domain {

#    bind 127.0.0.1
#    tls /etc/ssl/acme/your-domain/cert.pem /etc/ssl/acme/your-domain/key.pem


# Set this path to your site's directory.
    root * /var/www/$domain/


# Enable the static file server.
    file_server

# set /dl browser
    @dl {
        path /dl /dl/
    }
    file_server @dl browse


# Another common task is to set up a reverse proxy:
# reverse_proxy localhost:8080

# filebrowser v2
    @file {
        path /file /file/*
    }
    reverse_proxy @file localhost:8081


# Or serve a PHP site through php-fpm:
#php_fastcgi localhost:9000
#php_fastcgi unix//run/php/php7.0-fpm.sock
#### php install: apt install php-fpm


}
## $domain config END



## syncthing
#https://$domain:your-port {
#    reverse_proxy localhost:8384
#   }



# Refer to the Caddy docs for more information:
# https://caddyserver.com/docs/caddyfile

EOF

chmod 644 /etc/caddy/Caddyfile

## create file browser directories
mkdir -p /var/www/filebrowser/share
mkdir -p /var/www/filebrowser/dl

## create website directories
mkdir -p /var/www/$domain
rm -rf /var/www/$domain/dl
ln -s /var/www/filebrowser/dl /var/www/$domain/dl

## create default files

    if [ -f "/var/www/$domain/index.html" ]; then
        mv /var/www/$domain/index.html /var/www/$domain/index_backup.html
        echo "Found previous index.html, renamed to /var/www/$domain/index_backup.html"
    fi

cat > /var/www/$domain/index.html << EOF
<font size="8" face="Comic Sans MS"><center>
-- Welcome to $domain! --
</center></font>
EOF

echo "This is a test file for file browser" >> /var/www/filebrowser/test-filebrowser.txt
echo "This is a test file for /share" >> /var/www/filebrowser/share/test-share.txt
echo "This is a test file for /dl" >> /var/www/filebrowser/dl/test-dl.txt

#chmod -R 555 /var/www
#chmod -R 757 /var/www/filebrowser
chmod -R 750 /var/www


#### install filebroswer2

# download filebroswer2
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

# set user admin and password
passwd=$(openssl rand -base64 6)
filebrowser -d /etc/filebrowser/filebrowser.db users add admin $passwd --perm.admin


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


systemctl restart caddy
systemctl status caddy.service --no-pager

systemctl daemon-reload
systemctl enable filebrowser
systemctl restart filebrowser
systemctl status filebrowser --no-pager


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
