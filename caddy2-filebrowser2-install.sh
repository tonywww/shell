#!/bin/bash

echo ""
echo "Before install Caddy v2 & Filebroswer v2, make sure your domain has pointed to this VPS's IP."
echo "If you want to use Google reCAPCHA, please prepair the key and secret."
read -p "Please press \"y\" to continue: " answer

case $answer in
    Y|y)
    echo "continue..."


#### install Caddy

## input domain
echo -e "Please input your domain name: \c"
read domain

echo -e "Please input your Google reCAPCHA Key: \c"
read key

echo -e "Please input your Google reCAPCHA Secret: \c"
read secret


## download Caddy
apt-get update -y && apt-get install curl -y

apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/cfg/gpg/gpg.155B6D79CA56EA34.key' | apt-key add -
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/cfg/setup/config.deb.txt?distro=debian&version=any-version' | tee -a /etc/apt/sources.list.d/caddy-stable.list
apt-get update -y
apt-get install caddy


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
#:80

#### sniproxy change port
#   {
#    http_port  81
#    https_port 444
#   }



# $domain config START
#http://$domain, https://$domain {

$domain {


# Set this path to your site's directory.
    root * /www/website/

# Enable the static file server.
    file_server

    @dl {
       path /dl
       path /dl/
      }
    file_server @dl browse

# Another common task is to set up a reverse proxy:
# reverse_proxy localhost:8080

#filebrowser
    @file {
       path /file
       path /file/*
      }
    reverse_proxy @file localhost:8089

# Or serve a PHP site through php-fpm:
# php_fastcgi localhost:9000

#    php_fastcgi unix//run/php/php7.0-fpm.sock
####php 7.0 install
## apt-get install php-fpm


#### sniproxy librespeed test port forward
#    @https {
#        protocol https
#        path /speed
#       }
#    redir @https https://{host}:444/speed/

##    @http {
##        protocol http
##        path /speed
##       }
##    redir @http http://{host}:81/speed/


   }
# $domain config END



#### syncthing
#https://$domain:your-port {
#    reverse_proxy localhost:8384
#   }



# Refer to the Caddy docs for more information:
# https://caddyserver.com/docs/caddyfile

EOF

chmod 644 /etc/caddy/Caddyfile

## create file browser directories
mkdir -p /www/filebrowser/share
mkdir -p /www/filebrowser/dl

## create website directories
mkdir /www/website
ln -s /www/filebrowser/dl /www/website/dl

## create default files
cat > /www/website/index.html << EOF
<font size="8" face="Comic Sans MS"><center>
-- Welcome to $domain! --
</center></font>
EOF

echo "This is a test file for file browser" >> /www/filebrowser/test-filebrowser.txt
echo "This is a test file for /share" >> /www/filebrowser/share/test-share.txt
echo "This is a test file for /dl" >> /www/filebrowser/dl/test-dl.txt
chown -R www-data:www-data /www
chmod -R 555 /www
chmod -R 757 /www/filebrowser


#### install filebroswer

# download filebroswer
curl -fsSL https://filebrowser.org/get.sh | bash

# config init
mkdir /etc/filebroswer
filebrowser -d /etc/filebrowser/filebrowser.db config init
filebrowser -d /etc/filebrowser/filebrowser.db config set --address 127.0.0.1 \
    --port 8089 \
    --baseurl "/file" \
    --root "/www/filebrowser/" \
    --log "/var/log/filebrowser.log" \
    --auth.method=json \
    --recaptcha.host https://recaptcha.net \
    --recaptcha.key "$key" \
    --recaptcha.secret "$secret" \
    --locale "zh-cn"

# add user tony	
filebrowser -d /etc/filebrowser/filebrowser.db users add admin admin --perm.admin

# create systemd file and auto run
cat > /lib/systemd/system/filebrowser.service << EOF
[Unit]
Description=File browser
After=network.target

[Service]
;User=www-data
;Group=www-data
ExecStart=/usr/local/bin/filebrowser -d /etc/filebrowser/filebrowser.db

[Install]
WantedBy=multi-user.target

EOF


systemctl status caddy.service --no-pager

systemctl daemon-reload
systemctl enable filebrowser
systemctl start filebrowser
systemctl status filebrowser --no-pager


cat << EOF

=======================================================================
Caddy v2 path        : /usr/bin/caddy
Caddyfile path       : /etc/caddy/Caddyfile
Web service          : $domain       --> /www/website
Caddy browse         : $domain/dl    --> /www/filebroswer/dl

filebroswer v2 path  : /usr/local/bin/filemanager
filebroswer.db path  : /etc/filebroswer/filebroswer.db

Filebrowser          : $domain/file  --> /www/filebroswer
# Filebrowser share  : $domain/share --> /www/filebroswer/share
=======================================================================
Filebrowser default username & password : admin  admin
(Please login http://$domain/file and change the password ASAP!)

EOF



## go exit
    ;;


## end    
    *)
    echo "exit"
    ;;
esac
exit 0
