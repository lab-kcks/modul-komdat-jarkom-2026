# Implementasi DHCP

Pada bagian ini, praktikan akan melakukan implementasi DHCP secara langsung menggunakan GNS3.

Implementasi menggunakan:

- `debinet` untuk `suki` dan `aldarion`
- `alpinet` untuk DHCP Client
- `isc-dhcp-server` sebagai DHCP Server
- `isc-dhcp-relay` sebagai DHCP Relay

Topologi ini dibuat untuk mempraktikkan dua skenario DHCP:

1. Client berada pada subnet yang sama dengan DHCP Server.
2. Client berada pada subnet berbeda dan mendapatkan konfigurasi melalui DHCP Relay.

> **Catatan:** IP address pada contoh implementasi menggunakan `10.40.1.0/24` dan `10.40.2.0/24` agar langkah lebih mudah diikuti. Pada pengerjaan soal, sesuaikan seluruh alamat dengan prefix dan parameter yang diberikan.

---

## 1. Persiapan GNS3

### 1.1 Topologi

Buat topologi berikut pada GNS3.

![Topologi GNS3 Modul 3 DHCP](../images/01_topologi_gns3_dhcp.png)

Topologi terdiri dari:

| Node | Fungsi | Image |
|---|---|---|
| `NAT1` | Akses internet untuk instalasi package | NAT GNS3 |
| `suki` | Router + DHCP Relay | `debinet` |
| `aldarion` | DHCP Server | `debinet` |
| `alpha` | DHCP Client 1 | `alpinet` |
| `beta` | DHCP Client 2 | `alpinet` |
| `gamma` | DHCP Client 3 melalui Relay | `alpinet` |
| `delta` | DHCP Client 4 melalui Relay | `alpinet` |

### 1.2 Pembagian Jaringan

| Jaringan | Network | Gateway | Fungsi |
|---|---|---|---|
| Network 1 | `10.40.1.0/24` | `10.40.1.1` | DHCP Server + client langsung |
| Network 2 | `10.40.2.0/24` | `10.40.2.1` | Client melalui DHCP Relay |

Alamat statis contoh:

```text
suki eth1 = 10.40.1.1/24
suki eth2 = 10.40.2.1/24
aldarion  = 10.40.1.2/24
```

Client menggunakan DHCP.

### 1.3 Hubungan Interface

| Node | Interface | Terhubung ke |
|---|---|---|
| `suki` | `eth0` | NAT1 |
| `suki` | `eth1` | Switch1 |
| `suki` | `eth2` | Switch2 |
| `aldarion` | `eth0` | Switch1 |
| `alpha` | `eth0` | Switch1 |
| `beta` | `eth0` | Switch1 |
| `gamma` | `eth0` | Switch2 |
| `delta` | `eth0` | Switch2 |

Pastikan interface pada GNS3 sesuai dengan hasil `ip a` pada masing-masing node.

---

# 2. Konfigurasi Router `suki`

`suki` digunakan sebagai router yang menghubungkan dua subnet sekaligus sebagai DHCP Relay.

## 2.1 Periksa Interface

Masuk ke console `suki`, kemudian jalankan:

```bash
ip a
```

Pastikan terdapat `eth0`, `eth1`, dan `eth2`.

Gambaran konfigurasi:

```text
eth0 -> NAT1
eth1 -> Network 1
eth2 -> Network 2
```

---

## 2.2 Konfigurasi Interface

Edit file:

```bash
nano /etc/network/interfaces
```

Contoh konfigurasi:

```conf
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 10.40.1.1
    netmask 255.255.255.0

auto eth2
iface eth2 inet static
    address 10.40.2.1
    netmask 255.255.255.0
```

![Konfigurasi Interface suki](../images/02_suki_interfaces_ubuntu.png)

> Jangan mengubah konfigurasi `eth0` menjadi static jika interface tersebut digunakan untuk mendapatkan koneksi dari NAT GNS3. Sesuaikan dengan environment node yang digunakan.

Setelah selesai, verifikasi:

```bash
ip a
```

Kemudian:

```bash
ip route
```

Pastikan terdapat route untuk:

```text
10.40.1.0/24
10.40.2.0/24
```

---

## 2.3 Aktifkan IP Forwarding

Karena `suki` berfungsi sebagai router, packet harus dapat diteruskan antar-subnet.

Periksa status:

```bash
sysctl net.ipv4.ip_forward
```

Aktifkan:

```bash
sysctl -w net.ipv4.ip_forward=1
```

Periksa kembali:

```bash
sysctl net.ipv4.ip_forward
```

Hasil yang diharapkan:

```text
net.ipv4.ip_forward = 1
```

Agar konfigurasi tetap aktif setelah restart, edit:

```bash
nano /etc/sysctl.conf
```

Tambahkan:

```conf
net.ipv4.ip_forward=1
```

Terapkan:

```bash
sysctl -p
```

---

# 3. Konfigurasi DHCP Server `aldarion`

`aldarion` digunakan sebagai DHCP Server.

## 3.1 Pastikan Koneksi ke Internet

Pada `aldarion`:

```bash
ping -c 3 8.8.8.8
```

Jika belum dapat mengakses internet, periksa:

```bash
ip a
ip route
```

Pastikan default gateway tersedia.

---

## 3.2 Instalasi ISC DHCP Server

Update package:

```bash
apt update
```

Instal DHCP Server:

```bash
apt install isc-dhcp-server -y
```

Verifikasi:

```bash
dhcpd --version
```

![Instalasi dan Konfigurasi DHCP Server](../images/03_dhcp_server_ubuntu.png)

---

## 3.3 Tentukan Interface DHCP

Edit:

```bash
nano /etc/default/isc-dhcp-server
```

Tentukan interface yang terhubung ke jaringan client.

Contoh:

```conf
INTERFACESv4="eth0"
```

Periksa kembali topologi jika interface pada node berbeda.

---

## 3.4 Konfigurasi DHCP Pool

Edit:

```bash
nano /etc/dhcp/dhcpd.conf
```

Gunakan struktur berikut:

```conf
subnet 10.40.1.0 netmask 255.255.255.0 {
    range 10.40.1.100 10.40.1.200;
    option routers 10.40.1.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.40.1.255;
    option domain-name-servers 8.8.8.8;

    default-lease-time 600;
    max-lease-time 3600;
}
```

Keterangan:

| Parameter | Fungsi |
|---|---|
| `subnet` | Menentukan network DHCP |
| `range` | Menentukan rentang IP dinamis |
| `option routers` | Default gateway client |
| `option subnet-mask` | Subnet mask client |
| `option broadcast-address` | Broadcast address |
| `option domain-name-servers` | DNS yang diberikan ke client |
| `default-lease-time` | Lease time default |
| `max-lease-time` | Batas maksimum lease |

Pastikan seluruh nilai berada pada jaringan yang sesuai.

---

## 3.5 Validasi Konfigurasi

Sebelum menjalankan service, lakukan pengecekan:

```bash
dhcpd -t
```

Jika konfigurasi benar, tidak ada error syntax.

Jangan langsung melakukan restart service jika `dhcpd -t` masih menghasilkan error.

---

## 3.6 Jalankan DHCP Server

Restart service:

```bash
service isc-dhcp-server restart
```

Periksa:

```bash
service isc-dhcp-server status
```

![Validasi DHCP Server](../images/04_dhcp_validate_ubuntu.png)

Periksa juga apakah service diaktifkan saat boot:

```bash
systemctl is-enabled isc-dhcp-server
```

Jika belum:

```bash
systemctl enable isc-dhcp-server
```

---

# 4. Konfigurasi DHCP Client

## 4.1 Client `alpha`

Masuk ke console `alpha`.

Periksa interface:

```bash
ip a
```

Edit:

```bash
nano /etc/network/interfaces
```

Gunakan:

```conf
auto eth0
iface eth0 inet dhcp
```

Restart interface:

```bash
ifdown eth0 2>/dev/null
ifup eth0
```

Kemudian:

```bash
ip a
```

Client seharusnya memperoleh IP dari range:

```text
10.40.1.100 - 10.40.1.200
```

Periksa route:

```bash
ip route
```

Pastikan default gateway mengarah ke:

```text
10.40.1.1
```

---

## 4.2 Client `beta`

Lakukan langkah yang sama pada `beta`:

```bash
nano /etc/network/interfaces
```

```conf
auto eth0
iface eth0 inet dhcp
```

Kemudian:

```bash
ifdown eth0 2>/dev/null
ifup eth0
ip a
ip route
```

Pastikan `beta` mendapatkan IP yang berbeda dari `alpha`.

---

# 5. Konfigurasi DHCP Relay pada `suki`

DHCP Relay diperlukan karena `gamma` dan `delta` berada pada subnet berbeda dengan DHCP Server.

## 5.1 Instalasi DHCP Relay

Pada `suki`:

```bash
apt update
apt install isc-dhcp-relay -y
```

---

## 5.2 Tentukan DHCP Server

Edit:

```bash
nano /etc/default/isc-dhcp-relay
```

Gunakan:

```conf
SERVERS="10.40.1.2"
INTERFACES="eth1 eth2"
OPTIONS=""
```

`SERVERS` berisi alamat DHCP Server.

`INTERFACES` berisi interface yang terlibat dalam proses relay.

Pada topologi ini:

```text
eth1 -> Network 1 / DHCP Server
eth2 -> Network 2 / DHCP Client
```

![Konfigurasi DHCP Relay](../images/05_dhcp_relay_ubuntu.png)

---

## 5.3 Restart DHCP Relay

```bash
service isc-dhcp-relay restart
```

Periksa:

```bash
service isc-dhcp-relay status
```

---

## 5.4 Periksa IP Forwarding

```bash
sysctl net.ipv4.ip_forward
```

Hasil harus:

```text
net.ipv4.ip_forward = 1
```

Jika belum:

```bash
sysctl -w net.ipv4.ip_forward=1
```

---

# 6. Konfigurasi Client melalui DHCP Relay

## 6.1 Client `gamma`

Pada `gamma`:

```bash
nano /etc/network/interfaces
```

Gunakan:

```conf
auto eth0
iface eth0 inet dhcp
```

![Konfigurasi DHCP Client](../images/06_client_dhcp_ubuntu.png)

Kemudian:

```bash
ifdown eth0 2>/dev/null
ifup eth0
```

Periksa:

```bash
ip a
```

Contoh hasil:

```text
inet 10.40.2.101/24
```

Periksa routing:

```bash
ip route
```

Default gateway harus mengarah ke:

```text
10.40.2.1
```

---

## 6.2 Client `delta`

Lakukan konfigurasi yang sama pada `delta`:

```bash
nano /etc/network/interfaces
```

```conf
auto eth0
iface eth0 inet dhcp
```

Kemudian:

```bash
ifdown eth0 2>/dev/null
ifup eth0
```

Periksa:

```bash
ip a
ip route
```

`delta` harus memperoleh IP dari subnet:

```text
10.40.2.0/24
```

---

# 7. Mengatur Lease Time

Lease time dapat diatur pada `/etc/dhcp/dhcpd.conf`.

Contoh:

```conf
default-lease-time 600;
max-lease-time 3600;
```

Nilai menggunakan satuan detik.

```text
600  detik = 10 menit
3600 detik = 1 jam
```

Setelah melakukan perubahan:

```bash
dhcpd -t
service isc-dhcp-server restart
```

Kemudian ulangi pengujian DHCP pada client.

---

# 8. Fixed Address

Selain memberikan IP secara dinamis, DHCP dapat memberikan alamat tertentu kepada client berdasarkan MAC Address.

## 8.1 Ambil MAC Address Client

Pada client:

```bash
ip link show eth0
```

Contoh:

```text
link/ether 02:42:ac:11:00:03
```

Simpan MAC Address tersebut.

---

## 8.2 Konfigurasi Fixed Address pada DHCP Server

Pada `aldarion`:

```bash
nano /etc/dhcp/dhcpd.conf
```

Tambahkan:

```conf
host gamma {
    hardware ethernet 02:42:ac:11:00:03;
    fixed-address 10.40.2.50;
}
```

Ganti MAC Address dan IP sesuai kebutuhan praktikum.

Setelah itu:

```bash
dhcpd -t
service isc-dhcp-server restart
```

---

## 8.3 Uji Fixed Address

Pada client:

```bash
ifdown eth0 2>/dev/null
ifup eth0
```

Kemudian:

```bash
ip a
```

Client seharusnya memperoleh fixed address yang telah ditentukan.

Jika ingin mempertahankan hardware address pada environment GNS3, konfigurasi interface dapat menggunakan:

```conf
hwaddress ether <MAC-ADDRESS>
```

Letakkan pada `/etc/network/interfaces`.

---

# 9. Analisis DHCP Packet

Konfigurasi DHCP sebaiknya tidak hanya diuji dari IP address.

Praktikan juga perlu melihat komunikasi DHCP yang terjadi di jaringan.

## 9.1 Menggunakan tcpdump

Pada client atau interface yang sesuai:

```bash
tcpdump -i eth0 -n 'port 67 or port 68'
```

Kemudian lakukan renew DHCP.

Contoh alur:

```text
DHCPDISCOVER
DHCPOFFER
DHCPREQUEST
DHCPACK
```

![Analisis DHCP DORA](../images/07_dora_ubuntu.png)

---

## 9.2 Analisis Wireshark

Jika capture dibuka menggunakan Wireshark, gunakan filter:

```text
dhcp
```

atau:

```text
bootp
```

Perhatikan:

- DHCP Message Type
- Transaction ID
- Client MAC Address
- Requested IP Address
- Server Identifier
- Lease Time
- DHCP Options

Praktikan harus dapat menghubungkan packet:

```text
DISCOVER
   ↓
OFFER
   ↓
REQUEST
   ↓
ACK
```

---

# 10. Memeriksa Lease pada DHCP Server

Pada `aldarion`, periksa:

```bash
cat /var/lib/dhcp/dhcpd.leases
```

Untuk pencarian yang lebih terarah:

```bash
grep -n "lease" /var/lib/dhcp/dhcpd.leases
```

Informasi tersebut dapat digunakan untuk mengetahui client yang telah mendapatkan lease.

---

# 11. Troubleshooting

## 11.1 DHCP Server tidak aktif

Periksa konfigurasi:

```bash
dhcpd -t
```

Kemudian:

```bash
service isc-dhcp-server status
```

Periksa interface:

```bash
ip a
```

Pastikan `INTERFACESv4` mengarah ke interface yang benar.

---

## 11.2 Client tidak mendapatkan IP

Periksa:

```bash
ip link
ip a
```

Kemudian periksa DHCP Server:

```bash
service isc-dhcp-server status
```

Lakukan packet capture:

```bash
tcpdump -i eth0 -n 'port 67 or port 68'
```

Pertanyaan yang perlu dijawab:

```text
Apakah DHCPDISCOVER terlihat?
Apakah DHCPOFFER terlihat?
Apakah DHCPREQUEST terlihat?
Apakah DHCPACK terlihat?
```

---

## 11.3 DHCP Relay tidak bekerja

Periksa pada `suki`:

```bash
service isc-dhcp-relay status
```

Kemudian:

```bash
sysctl net.ipv4.ip_forward
```

Pastikan:

```text
net.ipv4.ip_forward = 1
```

Periksa konfigurasi:

```bash
cat /etc/default/isc-dhcp-relay
```

Pastikan:

```text
SERVERS
INTERFACES
```

sudah sesuai topologi.

---

## 11.4 Range DHCP tidak sesuai subnet

Periksa kembali:

```text
Network
Subnet Mask
Range
Gateway
Broadcast
```

Pastikan range berada dalam subnet yang dideklarasikan.

---

# 12. Persistence

Konfigurasi dianggap selesai apabila service tetap berjalan setelah node direstart.

## 12.1 DHCP Server

Periksa:

```bash
systemctl is-enabled isc-dhcp-server
```

Jika belum:

```bash
systemctl enable isc-dhcp-server
```

## 12.2 DHCP Relay

Pada `suki`:

```bash
systemctl is-enabled isc-dhcp-relay
```

Jika belum:

```bash
systemctl enable isc-dhcp-relay
```

## 12.3 Restart Node

Setelah semua konfigurasi selesai, lakukan restart pada node sesuai kebutuhan.

Setelah node aktif kembali, periksa:

```bash
systemctl status isc-dhcp-server
```

Pada `suki`:

```bash
systemctl status isc-dhcp-relay
```

Pada client:

```bash
ip a
ip route
```

Client harus kembali memperoleh konfigurasi DHCP.

![Persistence DHCP](../images/09_persistence_ubuntu.png)

---

# 13. Final Verification

Sebelum melanjutkan ke pengerjaan soal, lakukan pemeriksaan berikut.

### `suki`

```bash
ip a
ip route
sysctl net.ipv4.ip_forward
service isc-dhcp-relay status
```

### `aldarion`

```bash
ip a
service isc-dhcp-server status
dhcpd -t
```

### `alpha`

```bash
ip a
ip route
```

### `beta`

```bash
ip a
ip route
```

### `gamma`

```bash
ip a
ip route
```

### `delta`

```bash
ip a
ip route
```

Hasil yang diharapkan:

```text
Network 1
alpha / beta
      ↓
DHCP Server aldarion

Network 2
gamma / delta
      ↓
DHCP Relay suki
      ↓
DHCP Server aldarion
```

---

# 14. Checklist Praktikan

Sebelum menyatakan implementasi DHCP selesai, pastikan:

- [ ] Topologi GNS3 sesuai.
- [ ] `suki` dapat mengakses internet.
- [ ] `suki` memiliki IP pada kedua subnet.
- [ ] IP forwarding aktif.
- [ ] `aldarion` memiliki IP statis.
- [ ] `isc-dhcp-server` terinstall.
- [ ] Interface DHCP Server sudah benar.
- [ ] DHCP Pool sudah benar.
- [ ] Gateway sudah benar.
- [ ] DNS sudah benar.
- [ ] Lease Time sudah dikonfigurasi.
- [ ] `alpha` memperoleh IP DHCP.
- [ ] `beta` memperoleh IP DHCP.
- [ ] DHCP Relay terinstall pada `suki`.
- [ ] `gamma` memperoleh IP melalui Relay.
- [ ] `delta` memperoleh IP melalui Relay.
- [ ] Fixed Address berhasil diuji.
- [ ] DORA dapat diamati menggunakan packet capture.
- [ ] Lease dapat ditemukan pada DHCP Server.
- [ ] DHCP Server aktif setelah restart.
- [ ] DHCP Relay aktif setelah restart.

---

# 15. Catatan Penting

Contoh konfigurasi pada bagian implementasi menggunakan alamat:

```text
10.40.1.0/24
10.40.2.0/24
```

Alamat tersebut digunakan untuk mempermudah pembelajaran dan pembuatan hands-on.

Pada pengerjaan soal praktikum:

1. Gunakan prefix kelompok yang diberikan.
2. Sesuaikan network dan subnet.
3. Sesuaikan range DHCP.
4. Sesuaikan gateway.
5. Sesuaikan DNS.
6. Sesuaikan interface berdasarkan topologi.
7. Jangan menyalin contoh IP secara langsung apabila tidak sesuai dengan soal.

Tujuan hands-on adalah memahami proses konfigurasi dan verifikasi, bukan menghafalkan nilai konfigurasi.
