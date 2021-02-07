#!/bin/bash

echo ""
echo "This shell will install Filebrowser v2."
echo "If you want to use Google reCAPCHA, please prepair the key and secret."
read -p "Please press \"y\" to continue: " answer

case $answer in
    Y|y)
    echo "continue..."


## input key & secret
echo -e "Please input your Google reCAPCHA Key: \c"
read key
echo -e "Please input your Google reCAPCHA Secret: \c"
read secret


# download filebroswer
    if [ ! -x "/usr/bin/curl" ]; then 
       apt-get update -y && apt-get install curl -y
    fi
curl -fsSL https://filebrowser.org/get.sh | bash


# config init
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


systemctl daemon-reload
systemctl enable filebrowser
systemctl start filebrowser
systemctl status filebrowser --no-pager


cat << EOF

=======================================================================
filebroswer v2 path  : /usr/local/bin/filemanager
filebroswer.db path  : /etc/filebroswer/filebroswer.db

listen address       : 127.0.0.1
listen port          : 8091
root path            : /file  --> /www/filebroswer
config document      : https://filebrowser.org/cli/filebrowser-config-set
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
