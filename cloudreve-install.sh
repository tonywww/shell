#!/bin/bash

cat << EOF
#
# cloudreve-install.sh
# This shell scipts will install Cloudreve.
#
EOF

read -p "Please press \"y\" to continue: " answer

case $answer in
    Y|y)
    echo "continue..."

    if ! command -v tar >/dev/null 2>&1; then
       apt update -y && apt install tar -y
    fi

wget -O "cloudreve_3.2.1_linux_amd64.tar.gz" "https://github.com/cloudreve/Cloudreve/releases/download/3.2.1/cloudreve_3.2.1_linux_amd64.tar.gz"

mkdir -p /var/www/cloudreve
tar -zxvf cloudreve_*_linux_amd64.tar.gz -C /var/www/cloudreve
chown -R www-data:www-data /var/www/cloudreve
chmod 750 /var/www/cloudreve/cloudreve

echo "Please wait Cloudreve init..."
runuser -u www-data nohup /var/www/cloudreve/cloudreve > /var/www/cloudreve/cloudreve-install-info.txt 2>&1 &
sleep 5s
pkill -f /var/www/cloudreve/cloudreve
sleep 5s


# create systemd file and auto run
cat > /etc/systemd/system/cloudreve.service << EOF
[Unit]
Description=Cloudreve
Documentation=https://docs.cloudreve.org
After=network.target
After=mysqld.service
Wants=network.target

[Service]
User=www-data
WorkingDirectory=/var/www/cloudreve
ExecStart=/var/www/cloudreve/cloudreve
Restart=on-abnormal
RestartSec=5s
KillMode=mixed

StandardOutput=null
StandardError=syslog

[Install]
WantedBy=multi-user.target
EOF


systemctl daemon-reload
systemctl enable cloudreve
systemctl restart cloudreve
systemctl status cloudreve --no-pager

cat /var/www/cloudreve/cloudreve-install-info.txt

cat << EOF

=======================================================================
Cloudreve path        : /var/www/cloudreve/cloudreve
Config path           : /var/www/cloudreve/conf.ini
Default password      : /var/www/cloudreve/cloudreve-install-info.txt
=======================================================================
(Please login http://your-domain:5212 and change the password ASAP!)

EOF



## go exit
    ;;


## end    
    *)
    echo "exit"
    ;;

esac

exit 0
