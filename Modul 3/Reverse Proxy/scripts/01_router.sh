#!/bin/bash
# Setup Awal Router (Jaringan, NAT, & Akses Internet)

cat >> /root/.bashrc <<'EOF'
# Inisialisasi Jaringan Router (Hubungkan eth0 ke NAT1)
ifup eth0 2>/dev/null
if ! ip -4 addr show dev eth0 | grep -q "inet"; then
    ip addr add 192.168.122.100/24 dev eth0 2>/dev/null
    ip link set eth0 up
    ip route replace default via 192.168.122.1
fi

# Gateway Subnet 1 & Subnet 2
ip addr add 10.91.1.1/24 dev eth1 2>/dev/null
ip addr add 10.91.2.1/24 dev eth2 2>/dev/null
ip link set eth1 up
ip link set eth2 up

# Routing dan NAT Masquerade
sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null

# DNS Resolver
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
EOF

source /root/.bashrc
echo "[Router] Setup jaringan awal selesai."
