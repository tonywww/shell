#!/bin/bash

while [ $# -gt 0 ]; do
    case $1 in
    -\? | --help)
        cat <<EOF
Usage: ./acme.sh-cloudflare.sh <command> [parameters]
Commands:
  -?, --help                   Show this help message
  -f, --force                  Force install, force cert renewal or override sudo restrictions.
  -r, --reload <'command'>     Reload command after renew certificate
  -u, --auto-upgrade           Enable auto upgrade
EOF
        exit 1
        ;;
    -f | --force)
        force="--force"
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
        ;;
    esac
    shift
done

no_command() {
    if ! command -v $1 >/dev/null 2>&1; then
        if [ -z "$3" ]; then
            $2 install -y $1
        else
            $2 install -y $3
        fi
    fi
}

# check acme.sh, if it exist, then issue certificates

cat <<EOF

Usage: ./acme.sh-cloudflare.sh <command> [parameters]
Commands:
  -?, --help                   Show this help message
  -f, --force                  Force install, force cert renewal or override sudo restrictions.
  -r, --reload <'command'>     reload command after renew certificate
  -u, --auto-upgrade           Enable auto upgrade
EOF

if [ ! -x "/root/.acme.sh/acme.sh" ]; then

    cat <<EOF
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

    read -p "Continue? [y/n] " answer1

    case $answer1 in
    Y | y)
        echo "continue..."

        # choose default server
        cat <<EOF

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
        debian | ubuntu)
            echo System OS is $PRETTY_NAME
            apt update
            no_command curl apt
            no_command idn apt
            no_command cron apt
            ;;

        centos | fedora | rhel | sangoma)
            echo System OS is $PRETTY_NAME

            no_command bc yum bc
            yumdnf="yum"
            if test "$(echo "$VERSION_ID >= 22" | bc)" -ne 0; then
                yumdnf="dnf"
            fi

            no_command curl $yumdnf
            no_command idn $yumdnf
            no_command cron $yumdnf
            ;;

        *)
            echo System OS is $PRETTY_NAME
            echo Unsupported system OS.
            exit 2
            ;;
        esac

        # install acme.sh
        curl https://get.acme.sh | sh

        # set default server
        ~/.acme.sh/acme.sh --set-default-ca --server $server
        ;;

    *)
        echo "exit"
        exit 1
        ;;

    esac

else

    cat <<EOF

# Found acmd.sh in /root/.acmd.sh/!
#
# This shell will issue certificates with Cloudflare DNS API.
# Please make sure the domain's DNS is managed by Cloudflare.
EOF

fi

cat <<EOF
#
# Cloudflare DNS API doesn't support .tk/.cf/.ga/.gq/.ml domains.
# For those domains should use DNS alias mode.
#
# For example, if you use DNS alias mode, first you must set CNAME like bellow:
#
#   CNAME:
#   _acme-challenge.example.com
#      =>   _acme-challenge.aliasDomainForValidationOnly.com
#
# DNS alias mode documents:
# https://github.com/acmesh-official/acme.sh/wiki/DNS-alias-mode
#

EOF

read -p "Do you want use DNS alias mode? [y/n] " aliasmode

case $aliasmode in
y | Y)

    # get alias domain
    while true; do
        read -p "Please input your DNS alias domain: " alias
        if [ -z "$alias" ]; then
            cat <<EOF
DNS alias domain name is required.
Please try again, or press Ctrl+C to break and exit.

EOF
            continue
        fi
        break
    done

    alias="--challenge-alias $alias"
    ;;

*)
    echo "DNS alias mode: off"
    ;;
esac

cat <<EOF

1. issue ZeroSSL 90 days certificates (Default)*
2. issue BuyPass 180 days certificates
3. issue Let’s encrypt 90 days certificates
4. issue ZeroSSL 90 days WILDCARD certificates
5. exit

EOF

# auto upgrade
if [ "$upgrade" = true ]; then
    ~/.acme.sh/acme.sh --upgrade --auto-upgrade
    echo acme.sh auto upgrade is enabled!
    echo ""
fi

# choose issuer
read -p "Please choose your option: [1-5]" answer3
case $answer3 in

1 | "")
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
1 | 2 | 4 | "")
    echo "(If you already have registered on this server, just press enter to ignore.) "
    read -p "Please input your e-mail to register $issuer: " email

    if [ -n "$email" ]; then
        echo "email="$email
        ~/.acme.sh/acme.sh --register-account --server $issuer -m $email
    fi
    # continue check
    ;;&

1 | 2 | 3 | 4 | "")
    if [ -z "$days" ]; then
        days=60
    fi
    echo "server="$issuer
    echo "renew days="$days

    # get domain
    while true; do
        read -p "Please input your $wildcard domain name(without www.): " domain
        if [ -z "$domain" ]; then
            cat <<EOF
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
        read -p "Do you want both $domain and www.$domain in the certificate? [y/n] " www

        case $www in
        N | n) ;;

        *)
            subdomain=www.$domain
            ;;
        esac

        domain_path=$domain
    fi

    # get cloudflare token & zone_id and domain name
    while true; do
        read -p "Please input your Cloudflare API token: " cf_token

        if [ -n "$alias" ]; then
            read -p "Please input the ZONE ID for $alias: " cf_zone_id
        else
            read -p "Please input the ZONE ID for $domain: " cf_zone_id
        fi

        if [ -z "$cf_token" ] || [ -z "$cf_zone_id" ]; then
            cat <<EOF
Both API token and ZONE ID are required.
Please try again, or press Ctrl+C to break and exit.

EOF
            continue
        fi
        break
    done

    # export CF DNS API
    export CF_Token="$cf_token"
    export CF_Zone_ID="$cf_zone_id"

    # issue certificates
    ~/.acme.sh/acme.sh --issue --dns dns_cf --dnssleep 10 \
        $alias $force \
        --server $issuer --days $days \
        -d $domain -d $subdomain

    # install certificates to /etc/ssl/acme/
    mkdir /etc/ssl/acme/$domain_path -p
    if [ ! -n "$reload" ]; then
        reload="(systemctl restart xray ; systemctl restart caddy)"
    fi
    ~/.acme.sh/acme.sh --install-cert -d $domain \
        --reloadcmd "$reload" \
        --cert-file /etc/ssl/acme/$domain_path/cert.pem \
        --key-file /etc/ssl/acme/$domain_path/key.pem \
        --fullchain-file /etc/ssl/acme/$domain_path/fullchain.pem

    # change user & group, add read permission
    #check OS
    case $ID in
    # debian START
    debian | ubuntu)
        chown nobody:nogroup /etc/ssl/acme/$domain_path -R
        ;;
    # debian END
    # centos START
    centos | fedora | rhel | sangoma)
        chown nobody:nobody /etc/ssl/acme/$domain_path -R
        ;;
        # centos END
    esac

    chmod +r /etc/ssl/acme/$domain_path/key.pem

    cat <<EOF

$issuer $wildcard certificates for $domain is installed in "/etc/ssl/acme/$domain_path/" !
The certificates will be automatically renewed every $days days.

ls -lshF /etc/ssl/acme/$domain_path
EOF

    ls -lshF /etc/ssl/acme/$domain_path

    cat <<EOF

List all certificates:
~/.acme.sh/acme.sh --list

EOF
    ~/.acme.sh/acme.sh --list

    cat <<EOF

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
