#!/bin/bash

while [ $# -gt 0 ]; do
    case $1 in
        -\? | --help)
cat << EOF
Usage: ./acme.sh-cloudflare.sh <command> ... [parameters ...]
Commands:
  -?, --help                   Show this help message
  -a, --alias <domain-name>    DNS alias mode
  -r, --reload <'command'>     Reload command after renew certificate
  -u, --auto-upgrade           Enable auto upgrade
EOF
            exit 1
            ;;
        -a | --alias)
            alias=$2
            shift
            ;;
        -r | --reload)
            reload=$2
            shift
            ;;
        -u | --auto-upgrade)
            upgrade=true
            ;;
        *)
            echo Unknown option: \"$1\"
            echo For help:
            echo ./acme.sh-cloudflare.sh --help
            exit 2
    esac
    shift
done


# check acme.sh, if it exist, then issue certificates
if [ ! -x "/root/.acme.sh/acme.sh" ]; then 

cat << EOF
#
# acme.sh-cloudflare.sh
# Support OS: Debian / Ubuntu / CentOS
#
# This shell will install acme.sh and issue certificates with Cloudflare DNS API.
# After installed acme.sh, also can use this shell to issue certificates.
#
# Please make sure get your Cloudflare API token and ZONE ID first
#
# Generate a new token at https://dash.cloudflare.com/profile/api-tokens
# Create a custom token with these settings:
#     Permissions:
#         Zone - DNS - Edit
#     Zone Resources:
#         Include - Specific Zone - <your-domain>
#
EOF

    read -p "Continue? [y/n} " answer1

    case $answer1 in
    Y|y)
    echo "continue..."


no_command() {
    ! command -v "$1" > /dev/null 2>&1
}

# get cloudflare token & zone_id and domain name
    while true
    do
    read -p "Please input your Cloudflare API token: " cf_token
    read -p "Please input your Cloudflare ZONE ID: " cf_zone_id
    if [ -z "$cf_token" ] || [ -z "$cf_zone_id" ]; then
cat << EOF
Both API tokn and ZONE ID are required.
Please try again, or press Ctrl+C to break and exit.

EOF
    continue
    fi
    break
    done

# choose default server
cat << EOF

Please choose the default server:
1. ZeroSSL       (90 days)  (Default)*
2. BuyPass       (180 days)
3. Let’s encrypt (90 days)

EOF
        read -p "Please choose your option: [1-3]" answer2
        case $answer2 in  
        3)
        server="letsencrypt"
		;;
        2)
        server="buypass"
        ;;
        *)
        server="zerossl"
        ;;
        esac

#check OS
source /etc/os-release

        case $ID in
    # debian START
    debian|ubuntu|devuan)
    echo System OS is $PRETTY_NAME
    apt update
    if no_command curl; then
       apt install curl -y
    elif no_command idn; then
       apt install idn -y
    elif no_command cron ; then
       apt install cron -y
    fi
    ;;
    # debian END
    # centos START
    centos|fedora|rhel|sangoma)
    echo System OS is $PRETTY_NAME
    if no_command curl; then
       yum install curl -y
    elif no_command idn; then
       yum install idn -y
    elif no_command cron; then
       yum install cron -y
    fi
    ;;
    # centos END
        esac

# install acmd.sh
curl https://get.acme.sh | sh

# export CF DNS API
export CF_Token="$cf_token"
export CF_Zone_ID="$cf_zone_id"

# set default server
~/.acme.sh/acme.sh --set-default-ca  --server $server
    ;;

    *)
    echo "exit"
    exit 1
    ;;

    esac

else

cat << EOF

# Found acmd.sh in /root/.acmd.sh/!
#
# This shell will issue certificates with Cloudflare DNS API.
# Please make sure the domain's DNS is managed by Cloudflare.
EOF

fi


cat << EOF
#
# Usage: ./acme.sh-cloudflare.sh <command> ... [parameters ...]
# Commands:
#   -?, --help                   Show this help message
#   -a, --alias <domain-name>    DNS alias mode
#   -r, --reload <'command'>     reload command after renew certificate
#   -u, --auto-upgrade           Enable auto upgrade
#
#
# Cloudflare DNS API doesn't support .tk/.cf/.ga/.gq/.ml domains.
# For those domains should use DNS alias mode.
#
# DNS alias mode documents:
# https://github.com/acmesh-official/acme.sh#11-issue-wildcard-certificates
# https://github.com/acmesh-official/acme.sh/wiki/DNS-alias-mode#6-challenge-alias-or-domain-alias
#
1. issue ZeroSSL 90 days certificates (Default)*
2. issue BuyPass 180 days certificates
3. issue Let’s encrypt 90 days certificates
4. issue ZeroSSL 90 days WILDCARD certificates
5. exit

EOF

# auto upgrade
    if [ "$upgrade" = true ]; then
        ~/.acme.sh/acme.sh  --upgrade  --auto-upgrade
        echo acme.sh auto upgrade is enabled!
        echo ""
    fi

# choose issuer
read -p "Please choose your option: [1-5]" answer3
case $answer3 in  

    1|"")
    echo "continue to issue ZeroSSL certificates..."
    issuer="zerossl"
# continue check 
    ;;&

    2)
    echo "continue to issue BuyPass certificates..."
    issuer="buypass"
    days=150
# continue check 
    ;;&

    3)
    echo "continue to issue Let’s encrypt certificates..."
    issuer="letsencrypt"
# continue check 
    ;;&

    4)
    echo "continue to issue ZeroSSL WILDCARD certificates..."
    issuer="zerossl"
    wildcard="WILDCARD"
# continue check 
    ;;&

# register account
    1|2|4|"")
    echo "(If you already have registered on this server, just press enter to ignore.) "
    read -p "Please input your e-mail to register $issuer: " email

    if [ -n "$email" ]; then
        echo "email="$email
        ~/.acme.sh/acme.sh --register-account --server $issuer -m $email
    fi
# continue check 
    ;;&

    1|2|3|4|"")
    if [ -z "$days" ]; then
        days=60
    fi
    echo "server="$issuer
    echo "renew days="$days

# get domain
    while true
    do
    read -p "Please input your $wildcard domain name(without www.): " domain
    if [ -z "$domain" ]; then
cat << EOF
Domain name is required.
Please try again, or press Ctrl+C to break and exit.

EOF
    continue
    fi
    break
    done

    if [ "$wildcard" = "WILDCARD" ]; then
        domain_path=wildcard.$domain
        subdomain=*.$domain
    else
        domain_path=$domain
        subdomain=www.$domain
    fi

# issue certificates
    if [ -n "$alias" ]; then
        ~/.acme.sh/acme.sh --issue --dns dns_cf \
            --challenge-alias  $alias \
            --server $issuer --days $days \
	        -d $domain -d $subdomain
    else
        ~/.acme.sh/acme.sh --issue --dns dns_cf \
            --server $issuer --days $days \
	        -d $domain -d $subdomain
    fi

# install certificates to /etc/ssl/acme/
mkdir /etc/ssl/acme/$domain_path -p
    if [ -n "$reload" ]; then
        ~/.acme.sh/acme.sh --install-cert -d $domain \
            --reloadcmd "$reload" \
            --cert-file      /etc/ssl/acme/$domain_path/cert.pem  \
            --key-file       /etc/ssl/acme/$domain_path/key.pem  \
            --fullchain-file /etc/ssl/acme/$domain_path/fullchain.pem
    else
        ~/.acme.sh/acme.sh --install-cert -d $domain \
            --cert-file      /etc/ssl/acme/$domain_path/cert.pem  \
            --key-file       /etc/ssl/acme/$domain_path/key.pem  \
            --fullchain-file /etc/ssl/acme/$domain_path/fullchain.pem
    fi

# change user & group, add read permission
#check OS
        case $ID in
    # debian START
    debian|ubuntu|devuan)
chown nobody:nogroup /etc/ssl/acme/$domain_path -R
    ;;
    # debian END
    # centos START
    centos|fedora|rhel|sangoma)
chown nobody:nobody /etc/ssl/acme/$domain_path -R
    ;;
    # centos END
        esac

echo chmod +r /etc/ssl/acme/$domain_path/key.pem

cat << EOF

$issuer $wildcard certificates for $domain is installed in "/etc/ssl/acme/$domain_path/" !
The certificates will be automatically renewed every $days days.

ls -lshF /etc/ssl/acme/$domain_path
EOF

ls -lshF /etc/ssl/acme/$domain_path

cat << EOF

List all certificates:
~/.acme.sh/acme.sh --list

Manual renewal:
~/.acme.sh/acme.sh --renew -d <domain-name>

Stop auto renewal in the future:
~/.acme.sh/acme.sh --remove -d <domain-name>

EOF


# go exit
    ;;

    *)
    echo "exit"
    ;;

esac

exit 0
