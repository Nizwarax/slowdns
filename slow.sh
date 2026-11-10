#!/bin/bash
# =========================================
# Quick Setup | Script Setup Manager
# Edition : Stable Edition V3.0
# Auther  : Killer
# (C) Copyright 2023
# =========================================
# Color Validation
Lred='\e[1;91m'
Lgreen='\e[92m'
Lyellow='\e[93m'
green='\e[32m'
RED='\033[0;31m'
NC='\033[0m'
BGBLUE='\e[1;44m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0;37m'
# ===================
# // Export Banner Status Information
export EROR="[${RED} EROR ${NC}]"
export INFO="[${YELLOW} INFO ${NC}]"
export OKEY="[${green} OKEY ${NC}]"
export PENDING="[${YELLOW} PENDING ${NC}]"
export SEND="[${YELLOW} SEND ${NC}]"
export RECEIVE="[${YELLOW} RECEIVE ${NC}]"
clear
cd
echo -e "${green}Starting ${NC} ${Lyellow} Download Nameserver${NC}"
wget -q -O /root/ns.sh "https://nizwarax.github.io/slowdns/ns.sh" ; chmod +x ns.sh ; ./ns.sh >/dev/null 2>&1
nameserver=$(cat /etc/xray/ns.txt)
echo -e ""
clear
apt update -y
apt install -y python3 python3-dnslib net-tools
apt install ncurses-utils -y
apt install dnsutils -y
apt install golang -y
apt install screen -y
apt install iptables -y
echo -e ""
clear
echo -e "${OKEY} Starting ( ${green} Istall SlowDNS ${NC} )"
#// port
cd
mkdir -m 777 /etc/slowdns >/dev/null 2>&1
sleep 1
echo -e "${green}Starting ${NC} ${Lyellow} Download Plagin${NC}"
wget -q -O /root/plugin.zip "https://nizwarax.github.io/slowdns/plugin.zip" >/dev/null 2>&1
unzip plugin.zip >/dev/null 2>&1
rm -r -f plugin.zip
cd dnstt-plugin
cd dnstt-client
go build
mv dnstt-client /etc/slowdns/client
cd /root/dnstt-plugin/dnstt-server
go build
./dnstt-server -gen-key -privkey-file server.key -pubkey-file server.pub
mv dnstt-server /etc/slowdns/server
mv server.key /etc/slowdns/
mv server.pub /etc/slowdns/

chmod +x /etc/slowdns/server.key
chmod +x /etc/slowdns/server.pub
chmod +x /etc/slowdns/server
chmod +x /etc/slowdns/client
cd
rm -r -f /root/dnstt-plugin
#wget -O /usr/local/sbin/sd https://raw.githubusercontent.com/Nizwarax/project/main/slowdns/sd && chmod +x /usr/local/sbin/sd >/dev/null 2>&1
wget -q -O /etc/ssh/sshd_config "https://nizwarax.github.io/slowdns/sshd" >/dev/null 2>&1
chmod 700 /etc/ssh/sshd_config

#install client.service
cat > /etc/systemd/system/client.service << END
[Unit]
Description=Client SlowDNS
Documentation=https://tau_samawa
After=network.target nss-lookup.target
[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/etc/slowdns/client -udp 8.8.8.8:53 --pubkey-file /etc/slowdns/server.pub $nameserver 127.0.0.1:3369
Restart=on-failure
[Install]
WantedBy=multi-user.target
END
cd
#install server.service
cat > /etc/systemd/system/server.service << END
[Unit]
Description=Server SlowDNS
Documentation=https://gabutvpn.tech
After=network.target nss-lookup.target
[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/etc/slowdns/server -udp :5300 -privkey-file /etc/slowdns/server.key $nameserver 127.0.0.1:2269
Restart=on-failure
[Install]
WantedBy=multi-user.target
END
cd
# nano /etc/rc.local
cat > /etc/rc.local <<-END
#!/bin/sh -e
# rc.local
# By default this script does nothing.
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500
iptables -I INPUT -p udp --dport 5300 -j ACCEPT
iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
exit 0
END

# Ubah izin akses
chmod +x /etc/rc.local

# enable rc local
systemctl enable rc-local
systemctl start rc-local.service

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local
#// finnishing
echo -e "${OKEY} ( ${green} Finnishing${NC} )"
chmod +x /etc/systemd/system/client.service
chmod +x /etc/systemd/system/server.service
sudo apt remove apache2 -y >/dev/null 2>&1
sudo apt purge apache2 -y >/dev/null 2>&1
pkill server
pkill client
systemctl daemon-reload
systemctl stop client
systemctl stop server
systemctl enable client
systemctl enable server
systemctl start client
systemctl start server
systemctl restart client
systemctl restart server
systemctl restart ssh
systemctl restart sshd

cd
rm -f /root/slow.sh
clear
echo -e ""
sudo hostnamectl set-hostname GEOVPN
echo -e "${OKEY} Script Successfull Installed"
echo ""
read -p "$( echo -e "Press ${CYAN}[ ${NC}${green}Enter${NC} ${CYAN}]${NC} For Reboot") "
reboot
