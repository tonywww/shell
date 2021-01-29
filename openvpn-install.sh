#!/bin/bash

echo ""
read -p "Do you want to install OpenVPN (client & server) service? [y/n]" answer

case $answer in
    Y|y)
    echo "continue..."


## install openvpn
apt-get update -y
apt-get install openvpn gzip -y

# publice IP rules for OpenVPN client
#ip rule add from $(ip route get 1 | grep -Po '(?<=src )(\S+)') table 128
#ip route add table 128 to $(ip route get 1 | grep -Po '(?<=src )(\S+)')/32 dev $(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)')
#ip route add table 128 default via $(ip -4 route ls | grep default | grep -Po '(?<=via )(\S+)')
# rules for OpenVPN server 
#iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE


# add publice IP rules for OpenVPN
cat > /etc/network/if-up.d/openvpn-public-ip-rule << EOF
#!/bin/bash

# rules for OpenVPN client
ip rule add from \$(ip route get 1 | grep -Po '(?<=src )(\\S+)') table 128
ip route add table 128 to \$(ip route get 1 | grep -Po '(?<=src )(\\S+)')/32 dev \$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\\S+)')
ip route add table 128 default via \$(ip -4 route ls | grep default | grep -Po '(?<=via )(\\S+)')

# rules for OpenVPN server
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

EOF

cat > /etc/network/if-down.d/openvpn-public-ip-rule << EOF
#!/bin/bash

# rules for OpenVPN client
ip route del table 128 default via \$(ip -4 route ls | grep default | grep -Po '(?<=via )(\\S+)')
ip route del table 128 to \$(ip route get 1 | grep -Po '(?<=src )(\\S+)')/32 dev \$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\\S+)')
ip rule del from \$(ip route get 1 | grep -Po '(?<=src )(\\S+)') table 128

# rules for OpenVPN server
iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

EOF

chmod +x /etc/network/if-up.d/openvpn-public-ip-rule
chmod +x /etc/network/if-down.d/openvpn-public-ip-rule
/etc/network/if-up.d/openvpn-public-ip-rule


# enable ipv4 forward for this VPS's client to connect Internet
cat >> /etc/sysctl.conf << EOF
## enable ipv4 forward for OpenVPN server
net.ipv4.ip_forward = 1

EOF

# enable ipv4 forward
sysctl -p /etc/sysctl.conf


## OpenVPN client files download
#wget -O /etc/openvpn/client/sample-client.conf  "https://github.com/OpenVPN/openvpn/raw/master/sample/sample-config-files/client.conf"
#wget -O /etc/openvpn/server/server-sample.conf  "https://github.com/OpenVPN/openvpn/raw/master/sample/sample-config-files/server.conf"
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf /etc/openvpn/client/sample-client.conf
gzip -d /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz
cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/server/sample-server.conf

cat >> /etc/openvpn/client/sample-client.conf <<EOF


# change the message authentication algorithm (HMAC) from SHA1 to SHA256
auth SHA256

EOF

cat >> /etc/openvpn/server/sample-server.conf <<EOF


# change the message authentication algorithm (HMAC) from SHA1 to SHA256
auth SHA256

EOF

cat > /etc/openvpn/server/server.conf <<EOF
port 1194
proto udp
dev tun

server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 8.8.8.8"
client-to-client
keepalive 10 120

auth SHA256
cipher AES-256-CBC
ncp-ciphers AES-256-GCM:AES-128-GCM:AES-256-CBC:AES-128-CBC
compress lz4-v2
push "compress lz4-v2"
;comp-lzo
max-clients 20
persist-key
persist-tun

status openvpn-status.log
log-append  openvpn.log
verb 3
mute 20
explicit-exit-notify 1   # if TCP change to 0

ca ca.crt
cert server.crt
key server.key     # This file should be kept secret
dh dh2048.pem
tls-auth ta.key 0  # This file is secret

EOF

cat > /etc/openvpn/server/client.conf <<EOF
client
dev tun
proto udp
remote openvpndomain.name 1194

resolv-retry infinite
nobind
persist-key
persist-tun

auth SHA256
remote-cert-tls server
cipher AES-256-CBC
ncp-ciphers AES-256-GCM:AES-128-GCM:AES-256-CBC:AES-128-CBC
compress lz4-v2
;comp-lzo
verb 3
mute 20

ca ca.crt
cert client.crt
key client.key
tls-auth ta.key 1

;<ca>
;</ca>
;<cert>
;</cert>
;<key>
;</key>

;key-direction 1  # use it if tls-auth key is in this file
;<tls-auth>
;</tls-auth>

EOF


# disable openvpn service
systemctl disable openvpn.service


cat << EOF

OpenVPN has been installed!

server config file: /etc/openvpn/server/server.conf
client config file: /etc/openvpn/server/client.conf


Client start
systemctl start openvpn-client@client-conf-filename

Server start
systemctl start openvpn-server@server-conf-filename

Check status:
systemctl status openvpn-...

Set autorun:
systemctl enable openvpn-...

EOF


## go exit
    ;;


## end
    *)
    echo "exit"
    ;;
esac
exit 0
