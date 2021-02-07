#!/bin/bash

cat << EOF

# This shell will issue certificates with CloudFlare DNS API.
# Please make sure the domain's DNS is managed by CF.

1. issue BuyPass 180 days certificates (Default)
2. issue ZeroSSL 90 days certificates
3. issue Let’s encrypt 90 days certificates
4. exit

EOF

## make choice
read -p "Please choose your option: [1-4]" answer
case $answer in  


## choose BuyPass
    1)  
    echo "continue to issue BuyPass certificates..."
    issuer="buypass"
	days="150"
## continue check 
    ;;&

## choose ZeroSSL
    2)  
    echo "continue to issue ZeroSSL certificates..."
    issuer="zerossl"
	days="60"
## continue check 
    ;;&

## choose Let's encrypt
    3)  
    echo "continue to issue Let’s encrypt certificates..."
    issuer="letsencrypt"
	days="60"
## continue check 
    ;;&


## issue certificates
    1|2|3)  

echo "server="$issuer
echo "renew days="$days

# get domain name
echo -e "Please input your domain name: \c"
read domain

# get ssl certs
~/.acme.sh/acme.sh --issue --dns dns_cf \
    --server $issuer --days $days \
	-d $domain -d www.$domain

# install ssl certs to root/cert-files
mkdir ~/cert-files/$domain -p
~/.acme.sh/acme.sh --install-cert -d $domain \
    --cert-file      ~/cert-files/$domain/cert.pem  \
    --key-file       ~/cert-files/$domain/key.pem  \
    --fullchain-file ~/cert-files/$domain/fullchain.pem 

#                                                         \
#    --reloadcmd "systemctl reload nginx.service"


cat << EOF

$issuer certificates for $domain is installed!
The certificates will be automatically renewed every $days days.

ls ~/cert-files/$domain -lshF
EOF

ls ~/cert-files/$domain -lshF

cat << EOF

List all certificates:
acme.sh --list

Manual renewal:
acme.sh --renew -d <domain-name>

Stop auto renewal in the future:
acme.sh --remove -d <domain-name>

EOF



## go exit
    ;;

    *)
    echo "exit"
    ;;
esac
exit 0
