#!/bin/bash

cat << EOF
#
# caddy0.11.1-filemanager-install.sh
# This shell scipts will install Caddy v0.11.1 with FileManager(Filebroswer).
#
# Before the installation, please make sure your domain has pointed to this VPS's IP."
#
EOF

read -p "Please press \"y\" to continue: " answer

case $answer in
    Y|y)
    echo "continue..."

# install Caddy

## input domain
read -p "Please input your domain name (without www.): " domain

## download caddy v0.11.1 with filemanager
wget -O /usr/local/bin/caddy https://git.io/caddy0
chmod +x /usr/local/bin/caddy

## create etc & ssl path
mkdir /etc/caddy

## create /etc/caddy/Caddyfile
cat > /etc/caddy/Caddyfile << EOF
# Caddy v0.11.1 config file

# force whole site http to https
# (only work with sniproxy and xray/v2ray )
# sniproxy redirect http 80 to localhost 82
# xray/v2ray TLS fallback to http localhost 81
#    :82 {
#        bind 127.0.0.1
#        redir https://{host}{uri}
#    }


## $domain config START

#http://$domain, https://$domain {
$domain {

#    bind 127.0.0.1
    tls admin@$domain
    gzip
    root /var/www/$domain/
    browse /dl/
#    basicauth /dl/ username password

    timeouts {
        read none
        write none
        header none
        idle 5m
    }


    filemanager /file var/www/filebrowser/ {
        database /etc/ssl/caddy/filemanager/$domain.db
        locale         zh-cn
        allow_commands false
##        recaptcha_key       ??
##        recaptcha_secret    ??
##        alternative_recaptcha
    }

    filemanager /share var/www/filebrowser/share/ {
        database /etc/ssl/caddy/filemanager/$domain-share.db
        locale         zh-cn
        allow_commands false
        allow_new      false
        allow_edit     false
        allow_publish  false
        no_auth
    }


#    fastcgi / /run/php/php7.0-fpm.sock php
#    fastcgi / 127.0.0.1:9000 php
#### php 7.0 install: apt install php-fpm


}

## $domain config END



EOF

## create caddy directories
chown -R www-data:www-data /etc/caddy
chmod 644 /etc/caddy/Caddyfile

mkdir -p /etc/ssl/caddy/filemanager
chown -R www-data:www-data /etc/ssl/caddy
chmod -R 740 /etc/ssl/caddy

#chown -R root:www-data /etc/caddy
#mkdir -m 0770 /etc/ssl/caddy
#chown -R www-data:root /etc/ssl/caddy

## create file browser directories
mkdir -p /var/www/filebrowser/share
mkdir -p /var/www/filebrowser/dl

## create website directories
mkdir -p /var/www/$domain
rm -r /var/www/$domain/dl
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
chown -R www-data:www-data /var/www
chmod -R 750 /var/www

## create modified caddy.service file
cat > /etc/systemd/system/caddy.service << EOF

[Unit]
Description=Caddy v0.11.1 HTTP/2 web server
Documentation=https://caddyserver.com/docs
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Restart=on-abnormal

; User and group the process will run as.
User=www-data
Group=www-data

; Letsencrypt-issued certificates will be written to this directory.
Environment=CADDYPATH=/etc/ssl/caddy

; Always set "-root" to something safe in case it gets forgotten in the Caddyfile.
ExecStart=/usr/local/bin/caddy -log stdout -agree=true -conf=/etc/caddy/Caddyfile -root=/var/tmp
ExecReload=/bin/kill -USR1 $MAINPID

; Use graceful shutdown with a reasonable timeout
KillMode=mixed
KillSignal=SIGQUIT
TimeoutStopSec=5s

; Limit the number of file descriptors; see \`man systemd.exec\` for more limit settings.
LimitNOFILE=1048576
; Unmodified caddy is not expected to use more than that.
LimitNPROC=512

; Use private /tmp and /var/tmp, which are discarded after caddy stops.
PrivateTmp=true
; Use a minimal /dev (May bring additional security if switched to 'true', but it may not work on Raspberry Pi's or other devices, so it has been disabled in this dist.)
PrivateDevices=false
; Hide /home, /root, and /run/user. Nobody will steal your SSH-keys.
ProtectHome=true
; Make /usr, /boot, /etc and possibly some more folders read-only.
ProtectSystem=full
;   except /etc/ssl/caddy, because we want Letsencrypt-certificates there.
;   This merely retains r/w access rights, it does not add any new. Must still be writable on the host!
ReadWriteDirectories=/etc/ssl/caddy

# Debian 9 required
; The following additional security directives only work with systemd v229 or later.
; They further restrict privileges that can be gained by caddy. Uncomment if you like.
; Note that you may have to add capabilities required by any plugins in use.
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target

EOF

#chown root:root /etc/systemd/system/caddy.service
#chmod 644 /etc/systemd/system/caddy.service

## load Caddy as a system service & autorun
systemctl daemon-reload
systemctl disable caddy.service
systemctl enable caddy.service
systemctl restart caddy.service
echo "Please wait for web service starting..."
sleep 5s
echo "======================================================================="
systemctl status caddy.service --no-pager


cat << EOF

=======================================================================
Caddy v0.11.1 path   : /usr/local/bin/caddy
Caddyfile            : /etc/caddy/Caddyfile
Web service          : $domain       --> /var/www/website
Caddy browse         : $domain/dl    --> /var/www/filebroswer/dl

Filebrowser          : $domain/file  --> /var/www/filebroswer
Filebrowser share    : $domain/share --> /var/www/filebroswer/share
=======================================================================
EOF
echo -n "Filebrowser default username & password: "
echo -e "\033[5;46;30m"admin admin"\033[0m"
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
