#!/bin/bash
# 1 сервер 
echo "ENTER LOCAL IP: "
read localip

# Обновляем и ставим необходимые пакеты

apt-get update -y
apt-get install software-properties-common -y
add-apt-repository main
add-apt-repository universe
add-apt-repository restricted
add-apt-repository multiverse
apt-get update -y

apt-get update -y

apt-get install openvpn easy-rsa mc tmux atop htop tcpdump iptables-persistent zip -y

# Вносим правку в sysctl.conf
echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf
sysctl -p 

# Копируем  и создаем папки 
cp -r /usr/share/easy-rsa/ /etc/openvpn
mkdir /etc/openvpn/easy-rsa/keys

echo "edit vars"
awk '{gsub("EasyRSA", "server1", $0); print > FILENAME}' /etc/openvpn/easy-rsa/vars


cd /etc/openvpn/easy-rsa/
cp openssl-1.0.0.cnf openssl.cnf
source ./vars
echo "build keys for openvpn "

./clean-all
./build-ca --batch
./build-key-server --batch server1
./build-dh
openvpn --genkey --secret keys/ta.key

./build-key --batch client1
./build-key --batch client2
./build-key --batch client3
./build-key --batch client-pc
./build-key --batch client-sas

cp -r /etc/openvpn/easy-rsa/keys/ /etc/openvpn/
# Enter password for UP server 
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""

echo "Create dir for Windows client"
mkdir -p /etc/openvpn/win-client/



echo ""
echo ""
echo ""
echo ""
echo ""
echo ""

# Create config for windows client
echo "Copy key for Windows client "
cp /etc/openvpn/keys/{ta.key,ca.crt,client-pc.crt,client-pc.key} /etc/openvpn/win-client/


echo client > /etc/openvpn/win-client/client-pc.ovpn 
echo tls-client >> /etc/openvpn/win-client/client-pc.ovpn 
echo verb 3 >> /etc/openvpn/win-client/client-pc.ovpn 
echo dev tun >> /etc/openvpn/win-client/client-pc.ovpn 
echo proto udp >> /etc/openvpn/win-client/client-pc.ovpn 
echo remote $localip >> /etc/openvpn/win-client/client-pc.ovpn 
echo resolv-retry infinite >> /etc/openvpn/win-client/client-pc.ovpn 
echo nobind >> /etc/openvpn/win-client/client-pc.ovpn 
echo persist-key >> /etc/openvpn/win-client/client-pc.ovpn 
echo persist-tun >> /etc/openvpn/win-client/client-pc.ovpn 
echo ca ca.crt >> /etc/openvpn/win-client/client-pc.ovpn 
echo cert client-pc.crt >> /etc/openvpn/win-client/client-pc.ovpn 
echo key client-pc.key >> /etc/openvpn/win-client/client-pc.ovpn 
echo tls-auth ta.key 1 >> /etc/openvpn/win-client/client-pc.ovpn 
echo  # status     /var/log/openvpn.log >> /etc/openvpn/win-client/client-pc.ovpn 
echo # log-append /var/log/openvpn.log >> /etc/openvpn/win-client/client-pc.ovpn 
echo  keepalive 10 120 >> /etc/openvpn/win-client/client-pc.ovpn 
echo  comp-lzo >> /etc/openvpn/win-client/client-pc.ovpn 


# Создаем server.conf
echo " create server.conf"

echo dev tun > /etc/openvpn/server.conf
echo proto udp >> /etc/openvpn/server.conf
echo mode server >> /etc/openvpn/server.conf
echo tls-server >> /etc/openvpn/server.conf
echo server 192.168.111.0 255.255.255.0 >> /etc/openvpn/server.conf
echo push "redirect-gateway"  >> /etc/openvpn/server.conf
echo push "redirect-gateway def1 bypass-dhcp"  >> /etc/openvpn/server.conf
echo push "dhcp-option DNS 8.8.8.8" >> /etc/openvpn/server.conf
echo push "dhcp-option DNS 8.8.4.4" >> /etc/openvpn/server.conf
echo comp-lzo >> /etc/openvpn/server.conf
echo client-to-client >> /etc/openvpn/server.conf
echo daemon >> /etc/openvpn/server.conf
echo tls-server >> /etc/openvpn/server.conf
echo dh   /etc/openvpn/keys/dh2048.pem >> /etc/openvpn/server.conf
echo ca   /etc/openvpn/keys/ca.crt >> /etc/openvpn/server.conf
echo cert /etc/openvpn/keys/server1.crt >> /etc/openvpn/server.conf
echo key  /etc/openvpn/keys/server1.key >> /etc/openvpn/server.conf
echo tls-auth /etc/openvpn/keys/ta.key 0 >> /etc/openvpn/server.conf
echo keepalive 10 120 >> /etc/openvpn/server.conf
echo persist-tun >> /etc/openvpn/server.conf
echo persist-key >> /etc/openvpn/server.conf
echo verb 0 >> /etc/openvpn/server.conf
echo log /dev/null >> /etc/openvpn/server.conf



# Правим iptables 
echo " CREATE iptables rules" 

echo # START OPENVPN RULES > /etc/iptables/rules.v4
echo  # NAT table rules >> /etc/iptables/rules.v4
echo  *nat >> /etc/iptables/rules.v4
echo :POSTROUTING ACCEPT [0:0] >> /etc/iptables/rules.v4
echo # Allow traffic from OpenVPN client to eth0 >> /etc/iptables/rules.v4
echo -A POSTROUTING -s 192.168.111.0/24 -j MASQUERADE >> /etc/iptables/rules.v4
echo COMMIT >> /etc/iptables/rules.v4
echo # END OPENVPN RULES >> /etc/iptables/rules.v4
echo *filter >> /etc/iptables/rules.v4
echo :INPUT ACCEPT [0:0] >> /etc/iptables/rules.v4
echo :FORWARD ACCEPT [0:0] >> /etc/iptables/rules.v4
echo :OUTPUT ACCEPT [0:0] >> /etc/iptables/rules.v4
echo COMMIT >> /etc/iptables/rules.v4

echo "restart iptables"
service iptables-persistent restart

echo "RESTART openvpn"

service openvpn restart 

echo  Архивируем конфиг для windows 

cd /etc/openvpn/
zip /root/client-pc.zip ./win-client/*
cd ~
sleep 15 

ifconfig

echo " Если есть интерфейс tun0  то openvpn сервер скорее всего поднялся нормально "
