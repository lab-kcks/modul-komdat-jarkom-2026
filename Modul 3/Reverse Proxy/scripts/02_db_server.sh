#!/bin/bash
# Setup DB-Server (Simpan ke /root/.bashrc agar persisten di GNS3)

cat >> /root/.bashrc <<'EOF'
# Inisialisasi Jaringan DB-Server
ip addr add 10.91.2.10/24 dev eth0 2>/dev/null
ip link set eth0 up
ip route replace default via 10.91.2.1

echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# Instalasi MariaDB Server & Client
which mariadb >/dev/null 2>&1 || (apt-get update -y && apt-get install -y mariadb-server mariadb-client)
EOF

source /root/.bashrc
echo "[DB-Server] Setup persisten selesai."
