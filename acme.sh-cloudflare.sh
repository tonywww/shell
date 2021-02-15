#!/bin/bash

## This shell will install ACME.sh and issue certificates with CloudFlare DNS API.
## After installed ACME.sh, also can use this shell to issue certificates.


## check acme.sh, if it exist, then issue certificates
if [ ! -x "/root/.acme.sh/acme.sh" ]; then 

cat << EOF

# This shell will install acme.sh with CloudFlare DNS API and get free SSL certificate.
#
# Please make sure get your CloudFlare API token and ZONE ID first
#
# Generate a new token at https://dash.cloudflare.com/profile/api-tokens
# Create a custom token with these settings:
#     Permissions:
#         Zone - DNS - Edit
#     Zone Resources:
#         Include - Specific Zone - <your-domain>
#
# CloudFlare DNS API doesn't support .tk/.cf/.ga/.gq/.ml domains.
EOF

    read -p "Continue? [y/n} " answer1

    case $answer1 in
    Y|y)
    echo "continue..."

# get cloudflare token & zone_id and domain name
    read -p "Please input your CloudFlare API token: " cf_token
    read -p "Please input your CloudFlare ZONE ID: " cf_zone_id

# make choice
cat << EOF

Please choose the default server:
1. ZeroSSL       (90 days)  (Default)*
2. BuyPass       (180 days)
3. Let’s encrypt (90 days)

EOF
        read -p "Please choose your option: [1-3]" answer2
        case $answer2 in  
# choose default server
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

# install acmd.sh
    if [ ! -x "/usr/bin/curl" ]; then 
       apt update -y && apt install curl -y
    fi
curl https://get.acme.sh | sh

# export CF DNS API
export CF_Token="$cf_token"
export CF_Zone_ID="$cf_zone_id"

# set default server
acme.sh --set-default-ca  --server $server


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
# This shell will issue certificates with CloudFlare DNS API.
# Please make sure the domain's DNS is managed by CF.
EOF

fi


cat << EOF

1. issue ZeroSSL 90 days certificates (Default)*
2. issue BuyPass 180 days certificates
3. issue Let’s encrypt 90 days certificates
4. issue ZeroSSL 90 days WILDCARD certificates
5. exit

EOF

# choose issuer
read -p "Please choose your option: [1-5]" answer3
case $answer3 in  

    1|"")
    echo "continue to issue ZeroSSL certificates..."
    issuer="zerossl"
    days="60"
# continue check 
    ;;&

    2)
    echo "continue to issue BuyPass certificates..."
    issuer="buypass"
    days="150"
# continue check 
    ;;&

    3)
    echo "continue to issue Let’s encrypt certificates..."
    issuer="letsencrypt"
    days="60"
# continue check 
    ;;&

    4)
    echo "continue to issue ZeroSSL WILDCARD certificates..."
    issuer="zerossl"
    days="60"
# continue check 
    ;;&

# register account
    1|2|4|"")
    read -p "Please input your e-mail to register $issuer: " email
    acme.sh --register-account --server $issuer -m $email
    echo "e-mail="$email
# continue check 
    ;;&

    1|2|3|4|"")
    echo "server="$issuer
    echo "renew days="$days
# continue check 
    ;;&

    1|2|3|"")
# get domain name
read -p "Please input your domain name(without www.): " domain

# issue certificates
acme.sh --issue --dns dns_cf \
    --server $issuer --days $days \
	-d $domain -d www.$domain

# install certificates to /etc/ssl/acme/
mkdir /etc/ssl/acme/$domain -p
acme.sh --install-cert -d $domain \
    --reloadcmd "systemctl reload caddy.service" \
    --cert-file      /etc/ssl/acme/$domain/cert.pem  \
    --key-file       /etc/ssl/acme/$domain/key.pem  \
    --fullchain-file /etc/ssl/acme/$domain/fullchain.pem 
# continue check 
    ;;&

    4)
# get WILDCARD domain name
read -p "Please input your WINDCARD domain name(without www.): " domain

# issue WILDCARD certificates
acme.sh --issue --dns dns_cf \
    --server $issuer --days $days \
	-d $domain -d '*.$domain'

# install certificates to /etc/ssl/acme/
mkdir /etc/ssl/acme/*.$domain -p
acme.sh --install-cert -d $domain \
    --reloadcmd "systemctl reload caddy.service" \
    --cert-file      /etc/ssl/acme/*.$domain/cert.pem  \
    --key-file       /etc/ssl/acme/*.$domain/key.pem  \
    --fullchain-file /etc/ssl/acme/*.$domain/fullchain.pem 

domain=*.$domain
# continue check 
    ;;&

    1|2|3|4|"")
# change user & group, add read permission
chown nobody:nogroup /etc/ssl/acme/$domain -R
chmod +r /etc/ssl/acme/$domain/key.pem

cat << EOF

$issuer certificates for $domain is installed in "/etc/ssl/acme/$domain/" !
The certificates will be automatically renewed every $days days.

ls -lshF /etc/ssl/acme/$domain
EOF

ls -lshF /etc/ssl/acme/$domain

cat << EOF

List all certificates:
acme.sh --list

Manual renewal:
acme.sh --renew -d <domain-name>

Stop auto renewal in the future:
acme.sh --remove -d <domain-name>

EOF


# go exit
    ;;

    *)
    echo "exit"
    ;;

esac

exit 0
