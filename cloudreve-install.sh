#!/bin/bash

cat << EOF
#
# cloudreve-install.sh
# Support OS: Debian / Ubuntu / CentOS
#
# This shell scipts will install Cloudreve latest version.
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

#check OS
source /etc/os-release

        case $ID in
        debian|ubuntu|devuan)
        echo System OS is $PRETTY_NAME
    apt update
    no_command wget apt
    no_command curl apt
    no_command tar apt
    no_command pkill apt procps
        ;;

        centos|fedora|rhel|sangoma)
        echo System OS is $PRETTY_NAME
    no_command bc yum
    yumdnf="yum"
    if test "$(echo "$VERSION_ID >= 22" | bc)" -ne 0; then
        yumdnf="dnf"
    fi
    no_command wget $yumdnf
    no_command curl $yumdnf
    no_command tar $yumdnf
    no_command pkill $yumdnf procps-ng
        ;;
        esac

cd ~
curl -s https://api.github.com/repos/cloudreve/Cloudreve/releases/latest \
  | grep browser_download_url \
  | grep linux_amd64 \
  | cut -d '"' -f 4 \
  | wget -O cloudreve_linux_amd64.tar.gz -qi - 


mkdir -p /var/www/cloudreve
tar -zxvf cloudreve_linux_amd64.tar.gz -C /var/www/cloudreve
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
