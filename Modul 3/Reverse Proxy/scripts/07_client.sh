#!/bin/bash
# Setup Client (Simpan ke /root/.bashrc agar persisten di GNS3)

cat >> /root/.bashrc <<'EOF'
# Inisialisasi Jaringan Client
ip addr add 10.91.1.2/24 dev eth0 2>/dev/null
ip link set eth0 up
ip route replace default via 10.91.1.1

echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# Instalasi Utilitas Pengujian
which curl >/dev/null 2>&1 || (apt-get update -y && apt-get install -y curl apache2-utils lynx)
EOF

source /root/.bashrc
echo "[Client] Setup persisten selesai."
