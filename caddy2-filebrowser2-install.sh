#!/bin/bash

cat <<EOF
#
# caddy2-filebrowser2-install.sh
# Support OS: Debian / Ubuntu / CentOS
#
# This shell scipts will install Caddy v2 & Filebroswer v2.
#
# Before the installation, please make sure your domain has pointed to this VPS's IP.
# To use Google reCAPCHA, please have the key and secret ready.
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
    echo "(If leave the domain name empty, Caddy will runs http server only.)"
    read -p "Please input your domain name (without www.): " domain

    if [ -z "$domain" ]; then
        domain="domain"
        echo "No domain inputted. Caddy will runs http server only."
    else
        echo "Domain="$domain
    fi

    read -p "Please input listen port number(default:8081):" port
    if [ ! $port ]; then
        port=8081
    fi
    echo "listen port="$port

    read -p "Do you want File Browser listens on 0.0.0.0?(default:127.0.0.1) [y/n]" address
    if [[ "$address" = "Y" || "$address" = "y" ]]; then
        address="0.0.0.0"
    else
        address="127.0.0.1"
    fi
    echo "listen address="$address

    read -p "Do you want user Google reCAPCHA for File Browser? [y/n] " recapcha
    if [[ "$recapcha" = "Y" || "$recapcha" = "y" ]]; then
        while true; do
            read -p "Please input your Google reCAPCHA Key: " key
            read -p "Please input your Google reCAPCHA Secret: " secret
            if [ -z "$key" ] || [ -z "$secret" ]; then
                cat <<EOF

Both reCAPCHA key and secret are required.
Please try again, or press Ctrl+C to break and exit.

EOF
                continue
            fi
        break
        done
    fi

    #### install Caddy2

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
    debian | ubuntu)
        echo System OS is $PRETTY_NAME
        apt update
        no_command curl apt

        ## download Caddy2
        apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
        curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
        curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
        chmod o+r /usr/share/keyrings/caddy-stable-archive-keyring.gpg
        chmod o+r /etc/apt/sources.list.d/caddy-stable.list
        apt update
        apt install -y caddy
        ;;

    centos | rhel)
        echo System OS is $PRETTY_NAME
        no_command bc yum
        yumdnf="yum"
        if test "$(echo "$VERSION_ID >= 22" | bc)" -ne 0; then
            yumdnf="dnf"
            $yumdnf install -y 'dnf-command(copr)'
        else
            $yumdnf -y install yum-plugin-copr
        fi
        no_command curl $yumdnf
        adduser -r -d /var/www -s /sbin/nologin www-data -U

        $yumdnf -y install dnf-plugins-core
        $yumdnf -y copr enable @caddy/caddy
        $yumdnf -y install caddy
        ;;

    *)
        echo System OS is $PRETTY_NAME
        echo Unsupported system OS.
        exit 2
        ;;
    esac

    ## create /etc/caddy/Caddyfile
    cat >/etc/caddy/Caddyfile <<EOF
# The Caddyfile is an easy way to configure your Caddy web server.
#
# Unless the file starts with a global options block, the first
# uncommented line is always the address of your site.
#
# To use your own domain name (with automatic HTTPS), first make
# sure your domain's A/AAAA DNS records are properly pointed to
# this machine's public IP, then replace the line below with your
# domain name.


## Global options
{
# accept real client IP addresses from upstream proxies
    servers {
        listener_wrappers {
            proxy_protocol {
                # Optional: Only trust PROXY headers from specific IP ranges
                allow 10.0.0.1/24
            }
            tls
        }
        # Configures Caddy to trust the IPs within the PROXY header
        trusted_proxies static 10.0.0.1/24 127.0.0.1
    }
# set defalut CA to ZeroSSL
#        acme_ca https://acme.zerossl.com/v2/DV90
#        email   admin@$domain
# change default port
#        http_port  81
#        https_port 444
# auto_https
#   off: Disables both certificate automation and HTTP-to-HTTPS redirects.
#   disable_redirects: Disable only HTTP-to-HTTPS redirects.
#   disable_certs: Disable only certificate automation.
#        auto_https off
}


## http to https redir START
#http://$domain {
#    redir https://{host}{uri}
#}
## http to https redir END


## $domain config START
#http://$domain, https://$domain {
$domain {

#    bind 127.0.0.1
#    tls /etc/ssl/acme/your-domain/cert.pem /etc/ssl/acme/your-domain/key.pem


# Set this path to your site's directory.
    root * /var/www/$domain/


# Enable the static file server.
    file_server

# Set /dl browser
    @dl {
        path /dl /dl/
    }
    file_server @dl browse


# Set up a reverse proxy:

# filebrowser v2
    handle_path /file* {
        reverse_proxy 127.0.0.1:$port
    }

# nextcloud
#    handle_path /cloud* {
#        reverse_proxy 127.0.0.1:9001
#    }

# Serve a PHP site through php-fpm:
#php_fastcgi unix//run/php/php-fpm.sock
#### php install: apt install php-fpm

}
## $domain config END


## Syncthing
#https://$domain:your-port {
#    tls /etc/ssl/acme/your-domain/cert.pem /etc/ssl/acme/your-domain/key.pem
#    reverse_proxy 127.0.0.1:8384 {
#        # Changes the Host header to "127.0.0.1:8384"
#        header_up Host {http.reverse_proxy.upstream.hostport}
#    }
#}


# Refer to the Caddy docs for more information:
# https://caddyserver.com/docs/caddyfile

EOF

# if no domain then http only
    if [ "$domain" == "domain" ]; then
        sed -i 's/^domain {/http\:\/\/ {/'  /etc/caddy/Caddyfile
    fi

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

    cat >/var/www/$domain/index.html <<EOF
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html" />
<meta name="viewport" content="width=device-width" initial-scale="1"/>
<script language="javascript">host=location.hostname; // get host name </script>   
</head>
<style>
.comic-text {font-family: Comic Sans MS, Arial;}
.arial-text {font-family: Arial;}
</style>
<body>

<center>
<br>
<p style="font-size: 35px;" class="comic-text">
-- Welcome to <script language="javascript">document.write(""+host)</script>! --
</p>
<br><br>
<p style="font-size: 16px;" class="arial-text">
<a href="file/">File Browser</a> &emsp;
<a href="dl/">Download</a>
</center>
</p>

</body>
</html>
EOF

    echo "This is a test file for file browser" >>/var/www/filebrowser/test-filebrowser.txt
    echo "This is a test file for /share" >>/var/www/filebrowser/share/test-share.txt
    echo "This is a test file for /dl" >>/var/www/filebrowser/dl/test-dl.txt
    chmod -R 755 /var/www

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

    # config filebroswer2
    filebrowser -d /etc/filebrowser/filebrowser.db config init

        filebrowser -d /etc/filebrowser/filebrowser.db config set \
            --address $address --port $port \
            --baseurl "/file" \
            --root "/var/www/filebrowser/" \
            --log "/var/log/filebrowser.log" \
            --auth.method=json \
            --singleClick \
            --minimumPasswordLength "6" \
            --locale "zh-cn"

    if [[ "$recapcha" = "Y" || "$recapcha" = "y" ]]; then
        filebrowser -d /etc/filebrowser/filebrowser.db config set \
            --recaptcha.host https://recaptcha.net \
            --recaptcha.key "$key" \
            --recaptcha.secret "$secret"
    fi

    # set user admin and password
    passwd=$(openssl rand -base64 9)
    filebrowser -d /etc/filebrowser/filebrowser.db users add admin $passwd --perm.admin

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

    systemctl restart caddy
    systemctl status caddy.service --no-pager

    systemctl daemon-reload
    systemctl enable filebrowser
    systemctl restart filebrowser
    systemctl status filebrowser --no-pager

    cat <<EOF

=======================================================================
Caddy v2 path        : /usr/bin/caddy
Caddyfile path       : /etc/caddy/Caddyfile
Web service          : $domain       --> /var/www/$domain
Caddy browse         : $domain/dl    --> /var/www/filebroswer/dl

filebroswer v2 path  : /usr/local/bin/filemanager
filebroswer.db path  : /etc/filebroswer/filebroswer.db

Filebrowser          : $domain/file  --> /var/www/filebroswer
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
