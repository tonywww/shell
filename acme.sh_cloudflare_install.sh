#!/bin/bash

cat << EOF

# This shell will install acme.sh with CloudFlare DNS API and get Let’s Encrypt certificate.
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

read -p "Continue? [y/n} " answer

case $answer in
    Y|y)
    echo "continue..."


## get cloudflare token & zone_id and domain name
echo -e "Please input your CloudFlare API token: \c"
read cf_token
echo -e "Please input your CloudFlare ZONE ID: \c"
read cf_zone_id
echo -e "Please input your domain name: \c"
read domain

# install acmd.sh
curl https://get.acme.sh | sh

export CF_Token="$cf_token"
export CF_Zone_ID="$cf_zone_id"

# Get ssl certs
~/.acme.sh/acme.sh --issue --dns dns_cf -d $domain -d www.$domain

# Install ssl certs to root/cert-files
mkdir ~/cert-files/$domain -p
~/.acme.sh/acme.sh --install-cert -d $domain \
--cert-file      ~/cert-files/$domain/cert.pem  \
--key-file       ~/cert-files/$domain/key.pem  \
--fullchain-file ~/cert-files/$domain/fullchain.pem 

#                                                    \
#    --reloadcmd "systemctl reload nginx.service"


cat << EOF

Let’s Encrypt certificates for $domain is installed!
Certificates path: root/cert-files/$domain
ls ~/cert-files/$domain -lshF

The certificates will be automatically renewed every 60 days.


Issue certificate to new domain:
acme.sh --issue --dns dns_cf -d <domain-name>

Stop renewal in the future:
acme.sh --remove -d <domain-name>

EOF


## go exit
    ;;

    *)
    echo "exit"
    ;;
esac
exit 0
