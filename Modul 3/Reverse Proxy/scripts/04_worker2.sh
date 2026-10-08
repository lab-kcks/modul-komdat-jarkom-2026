#!/bin/bash
# Setup Worker2 (Simpan ke /root/.bashrc agar persisten di GNS3)

cat >> /root/.bashrc <<'EOF'
# Inisialisasi Jaringan Worker2
ip addr add 10.91.2.3/24 dev eth0 2>/dev/null
ip link set eth0 up
ip route replace default via 10.91.2.1

echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# Instalasi Web Server & PHP
which php >/dev/null 2>&1 || (apt-get update -y && apt-get install -y nginx php-fpm php-mysqli mariadb-client)
EOF

source /root/.bashrc
echo "[Worker2] Setup persisten selesai."
