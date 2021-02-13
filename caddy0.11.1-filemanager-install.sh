#!/bin/bash

echo ""
echo "Before install Caddy v0.11.1(with filemanager), make sure your domain has pointed to this VPS's IP."

read -p "Please press \"y\" to continue: " answer

case $answer in
    Y|y)
    echo "continue..."

# install Caddy

## input domain
echo -e "Please input your domain name: \c"
read domain

## download Caddy

# old install
#curl https://getcaddy.com | bash -s personal http.filebrowser
#curl https://getcaddy.com | bash -s personal
#cp /usr/local/bin/caddy /usr/local/bin/caddy_no-filemanager

## download caddy v0.11.1 with filemanager
wget -O /usr/local/bin/caddy_filemanager_v0.11.1 "https://github.com/tonywww/shell/raw/master/caddy_filemanager_v0.11.1"
cp /usr/local/bin/caddy_filemanager_v0.11.1 /usr/local/bin/caddy
chmod +x /usr/local/bin/caddy*

## create etc & ssl path
mkdir /etc/caddy
chown -R root:www-data /etc/caddy
mkdir -m 0770 /etc/ssl/caddy
chown -R www-data:root /etc/ssl/caddy

## create /etc/caddy/Caddyfile
cat > /etc/caddy/Caddyfile << EOF
## cloudflare SSL (Full strict)
# http://$domain, https://$domain {

$domain {
    tls admin@$domain
    gzip
    root /www/website/
    browse /dl/


    filemanager /file www/filebrowser/ {
        database /etc/ssl/caddy/filemanager/$domain.db
        locale         zh-cn
        allow_commands false
##        recaptcha_key       ??
##        recaptcha_secret    ??
##        alternative_recaptcha
       }

    filemanager /share www/filebrowser/share/ {
        database /etc/ssl/caddy/filemanager/$domain-share.db
        locale         zh-cn
        allow_commands false
        allow_new      false
        allow_edit     false
        allow_publish  false
        no_auth
       }


#    fastcgi / /run/php/php7.0-fpm.sock php
####php 7.0 install
## apt install php-fpm


#### sniproxy librespeed test port forward
#    redir 302 {
#	if {scheme} is https
#	/speed https://{host}:444/speed/
#       }
#    redir 302 {
#	if {scheme} is http
#	/speed http://{host}:81/speed/
#       }


}
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

## original caddy.service file
# For Debian9, the file \"/etc/systemd/system/caddy.service\" need to modified to:
# CapabilityBoundingSet=CAP_NET_BIND_SERVICE
# AmbientCapabilities=CAP_NET_BIND_SERVICE
# NoNewPrivileges=true

## create modified caddy.service file
cat > /etc/systemd/system/caddy.service << EOF

[Unit]
Description=Caddy HTTP/2 web server
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

; Allow Caddy File Browser to access the directory
ReadWriteDirectories=/www/filebrowser

; The following additional security directives only work with systemd v229 or later.
; They further restrict privileges that can be gained by caddy. Uncomment if you like.
; Note that you may have to add capabilities required by any plugins in use.
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target

EOF

chown root:root /etc/systemd/system/caddy.service
chmod 644 /etc/systemd/system/caddy.service

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
Caddy v0.11.1 path   : /usr/local/bin/caddy_filemanager_v0.11.1
Caddyfile            : /etc/caddy/Caddyfile
Web service          : $domain       --> /www/website
Caddy browse         : $domain/dl    --> /www/filebroswer/dl

Filebrowser          : $domain/file  --> /www/filebroswer
Filebrowser share    : $domain/share --> /www/filebroswer/share
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
