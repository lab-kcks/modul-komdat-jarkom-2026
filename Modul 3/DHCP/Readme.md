# Dynamic Host Configuration Protocol (DHCP)

## 1. Konsep

### 1.1 Pendahuluan

Dalam sebuah jaringan komputer, setiap perangkat membutuhkan konfigurasi jaringan agar dapat berkomunikasi dengan perangkat lain. Konfigurasi tersebut dapat dilakukan secara manual, tetapi metode ini menjadi kurang efisien ketika jumlah perangkat bertambah atau perangkat harus berpindah jaringan.

**Dynamic Host Configuration Protocol (DHCP)** merupakan protokol yang digunakan untuk memberikan konfigurasi jaringan kepada client secara otomatis.

Konfigurasi yang dapat diberikan oleh DHCP antara lain:

- IP Address
- Subnet Mask
- Default Gateway
- DNS Server
- Lease Time
- Parameter jaringan lainnya

Pada praktikum ini, DHCP tidak hanya dipelajari dari sisi instalasi dan konfigurasi. Praktikan juga akan mempelajari proses komunikasi DHCP, lease, DHCP Relay, Fixed Address, packet analysis, troubleshooting, dan persistence.

---

### 1.2 Tujuan Pembelajaran

Setelah menyelesaikan materi ini, praktikan diharapkan mampu:

1. Menjelaskan fungsi DHCP pada jaringan.
2. Menjelaskan proses kerja DHCP melalui mekanisme DORA.
3. Menjelaskan fungsi DHCP Message dan DHCP Options.
4. Mengonfigurasi DHCP Server.
5. Mengonfigurasi DHCP Client.
6. Mengatur DHCP Range dan DHCP Options.
7. Mengatur Lease Time.
8. Mengimplementasikan DHCP Relay.
9. Mengimplementasikan Fixed Address berdasarkan MAC Address.
10. Melakukan verifikasi konfigurasi DHCP.
11. Menganalisis komunikasi DHCP menggunakan packet capture.
12. Melakukan troubleshooting DHCP.
13. Memastikan service DHCP tetap berjalan setelah restart.

---

## 2. Dynamic Host Configuration Protocol

### 2.1 Apa itu DHCP?

DHCP merupakan protokol client-server yang memungkinkan client memperoleh konfigurasi jaringan secara otomatis dari DHCP Server.

Tanpa DHCP, administrator harus memberikan konfigurasi jaringan kepada setiap client secara manual.

Contoh konfigurasi manual:

```text
IP Address   : 192.168.10.20
Subnet Mask  : 255.255.255.0
Gateway      : 192.168.10.1
DNS Server   : 192.168.10.1
```

Pada jaringan dengan banyak client, konfigurasi manual dapat meningkatkan kemungkinan kesalahan seperti:

- IP Address berada pada subnet yang salah.
- Terjadi IP Address Conflict.
- Default Gateway salah.
- DNS Server salah.
- Proses konfigurasi menjadi lebih lama.

DHCP membuat konfigurasi tersebut dapat diberikan secara otomatis oleh server.

---

### 2.2 DHCP Server dan DHCP Client

DHCP menggunakan model client-server.

**DHCP Server** bertugas menyediakan konfigurasi jaringan.

**DHCP Client** meminta konfigurasi jaringan kepada server.

Gambaran sederhananya:

```text
DHCP Client
     |
     | Request
     v
DHCP Server
     |
     | Configuration
     v
DHCP Client
```

Server dapat memberikan IP Address dari kumpulan alamat yang telah ditentukan.

Kumpulan alamat tersebut disebut sebagai **DHCP Pool** atau **DHCP Range**.

---

### 2.3 DHCP Port

DHCPv4 menggunakan UDP sebagai transport protocol.

```text
DHCP Server : UDP 67
DHCP Client : UDP 68
```

Port tersebut digunakan dalam proses komunikasi antara client dan server.

Pada tahap awal, client belum mengetahui alamat DHCP Server. Oleh karena itu, komunikasi DHCP dapat menggunakan broadcast.

---

## 3. DHCP DORA

### 3.1 Gambaran DORA

Proses paling umum ketika sebuah client pertama kali meminta konfigurasi DHCP dikenal sebagai **DORA**.

DORA terdiri dari:

```text
DHCPDISCOVER
      ↓
DHCPOFFER
      ↓
DHCPREQUEST
      ↓
DHCPACK
```

---

### 3.2 DHCPDISCOVER

Client mengirimkan `DHCPDISCOVER` untuk mencari DHCP Server yang tersedia.

Pada kondisi awal, client belum memiliki konfigurasi IP yang dapat digunakan untuk komunikasi normal.

Gambaran:

```text
Client
  |
  | DHCPDISCOVER
  v
Network
```

Tujuan utama pesan ini adalah memberitahukan bahwa terdapat client yang membutuhkan konfigurasi DHCP.

---

### 3.3 DHCPOFFER

DHCP Server menerima `DHCPDISCOVER` dan dapat memberikan penawaran konfigurasi menggunakan `DHCPOFFER`.

Informasi yang dapat ditawarkan antara lain:

- IP Address
- Subnet Mask
- Default Gateway
- DNS Server
- Lease Time

---

### 3.4 DHCPREQUEST

Client menerima satu atau lebih penawaran dan memilih konfigurasi yang akan digunakan.

Client kemudian mengirimkan `DHCPREQUEST`.

Pesan ini menunjukkan bahwa client meminta konfigurasi tersebut kepada DHCP Server.

---

### 3.5 DHCPACK

DHCP Server memberikan konfirmasi menggunakan `DHCPACK`.

Setelah menerima ACK, client dapat menggunakan konfigurasi jaringan yang diberikan.

---

### 3.6 DHCPRELEASE

Selain empat pesan utama DORA, terdapat beberapa DHCP message lainnya.

Salah satunya adalah `DHCPRELEASE`.

Pesan ini digunakan client untuk memberitahukan kepada DHCP Server bahwa client tidak lagi menggunakan lease tertentu.

---

## 4. DHCP Message

DHCP Message memiliki beberapa field yang digunakan untuk mengidentifikasi dan mengatur proses komunikasi DHCP.

Beberapa informasi yang penting untuk dipahami:

- Transaction ID
- Client Hardware Address
- DHCP Message Type
- Requested IP Address
- Server Identifier
- Lease Time
- Subnet Mask
- Router
- Domain Name Server

Saat melakukan analisis packet, praktikan tidak cukup hanya melihat nama packet.

Perhatikan juga:

```text
Message Type
Transaction ID
Client MAC Address
Requested IP Address
Server Identifier
DHCP Options
```

Informasi tersebut dapat digunakan untuk mengikuti satu proses DHCP dari awal hingga selesai.

---

## 5. DHCP Options

DHCP dapat memberikan konfigurasi tambahan melalui DHCP Options.

Beberapa option yang umum digunakan:

### 5.1 Subnet Mask

```conf
option subnet-mask <NETMASK>;
```

Digunakan untuk memberikan subnet mask kepada client.

---

### 5.2 Default Gateway

```conf
option routers <GATEWAY>;
```

Digunakan untuk menentukan default gateway client.

---

### 5.3 DNS Server

```conf
option domain-name-servers <DNS-SERVER>;
```

Digunakan untuk memberikan alamat DNS Server kepada client.

---

### 5.4 Lease Time

Lease time juga dapat dikonfigurasi melalui:

```conf
default-lease-time <SECONDS>;
max-lease-time <SECONDS>;
```

Nilai waktu pada konfigurasi DHCP menggunakan satuan **detik**.

Contoh:

```conf
default-lease-time 600;
max-lease-time 3600;
```

Artinya:

```text
600 detik  = 10 menit
3600 detik = 1 jam
```

Nilai tersebut hanya digunakan sebagai contoh pemahaman sintaks. Parameter sebenarnya harus disesuaikan dengan kebutuhan jaringan.

---

## 6. DHCP Lease

### 6.1 Pengertian Lease

DHCP tidak selalu memberikan IP Address secara permanen.

IP Address yang diberikan kepada client biasanya memiliki periode penggunaan yang disebut **lease**.

Selama lease masih berlaku, client dapat menggunakan konfigurasi tersebut.

Ketika lease mendekati masa berakhir, client dapat melakukan proses renewal untuk mempertahankan konfigurasi.

---

### 6.2 Default Lease Time

`default-lease-time` menentukan lease time default yang diberikan kepada client.

Contoh:

```conf
default-lease-time <SECONDS>;
```

---

### 6.3 Maximum Lease Time

`max-lease-time` menentukan batas maksimum lease.

Contoh:

```conf
max-lease-time <SECONDS>;
```

Hubungan kedua parameter:

```text
default-lease-time
        |
        v
Lease default client

max-lease-time
        |
        v
Batas maksimum lease
```

---

## 7. DHCP Server

### 7.1 Instalasi

Pada environment Debian-based, DHCP Server dapat dipasang menggunakan:

```bash
apt update
apt install isc-dhcp-server
```

Setelah instalasi, beberapa file penting yang perlu diketahui adalah:

```text
/etc/dhcp/dhcpd.conf
/etc/default/isc-dhcp-server
/var/lib/dhcp/dhcpd.leases
```

Fungsi masing-masing:

| File | Fungsi |
|---|---|
| `/etc/dhcp/dhcpd.conf` | Konfigurasi utama DHCP Server |
| `/etc/default/isc-dhcp-server` | Menentukan interface DHCP Server |
| `/var/lib/dhcp/dhcpd.leases` | Menyimpan informasi lease |

---

### 7.2 Menentukan Interface

DHCP Server harus mengetahui interface yang digunakan untuk melayani client.

Periksa interface dengan:

```bash
ip addr
```

Contoh:

```text
eth0
eth1
eth2
```

Interface yang digunakan DHCP harus disesuaikan dengan topologi.

Contoh struktur konfigurasi:

```conf
INTERFACESv4="eth1"
```

Jangan menggunakan contoh tersebut secara langsung sebelum memastikan interface yang dimaksud memang terhubung ke jaringan client.

---

## 8. DHCP Server Configuration

### 8.1 Konfigurasi Subnet

Konfigurasi DHCP Server berada pada:

```text
/etc/dhcp/dhcpd.conf
```

Struktur dasar deklarasi subnet:

```conf
subnet <NETWORK> netmask <NETMASK> {
    range <START-IP> <END-IP>;
    option subnet-mask <NETMASK>;
    option routers <GATEWAY>;
    option domain-name-servers <DNS-SERVER>;

    default-lease-time <SECONDS>;
    max-lease-time <SECONDS>;
}
```

Perhatikan hubungan antarparameter:

```text
Network
   |
   +-- Netmask
   |
   +-- DHCP Range
   |
   +-- Gateway
   |
   +-- DNS Server
   |
   +-- Lease Time
```

DHCP Range harus berada pada jaringan yang sesuai dengan deklarasi subnet.

---

### 8.2 DHCP Range

`range` menentukan kumpulan IP Address yang dapat dialokasikan secara dinamis kepada client.

Contoh:

```conf
range <START-IP> <END-IP>;
```

Sebelum menentukan range, pastikan:

1. Network Address benar.
2. Subnet Mask benar.
3. Gateway berada pada subnet yang sama.
4. Range masih berada dalam jaringan tersebut.
5. Tidak terjadi overlap dengan IP statis atau fixed address.

---

### 8.3 Gateway

Gateway diberikan menggunakan:

```conf
option routers <GATEWAY>;
```

Gateway harus mengarah pada alamat router yang dapat digunakan client untuk keluar dari jaringan lokal.

---

### 8.4 DNS

DNS Server diberikan menggunakan:

```conf
option domain-name-servers <DNS-SERVER>;
```

Kesalahan DNS dapat menyebabkan client berhasil mendapatkan IP tetapi tidak dapat melakukan resolusi domain.

---

## 9. DHCP Client

Client harus dikonfigurasi agar dapat memperoleh IP Address dari DHCP Server.

Pada environment yang menggunakan `ifupdown`, konfigurasi dapat menggunakan:

```conf
auto eth0

iface eth0 inet dhcp
```

Sesuaikan interface dengan topologi.

Setelah konfigurasi diterapkan, periksa:

```bash
ip addr
```

Kemudian:

```bash
ip route
```

Hal-hal yang perlu diverifikasi:

```text
IP Address       ✓
Subnet Mask      ✓
Default Gateway  ✓
DNS Server       ✓
```

Mendapatkan IP Address saja belum cukup untuk menyatakan DHCP telah dikonfigurasi dengan benar.

---

## 10. DHCP Client Lease

Pada sisi client, informasi mengenai lease dapat diperiksa sesuai mekanisme DHCP client yang digunakan.

Pada sisi server, informasi lease dapat dilihat melalui:

```bash
cat /var/lib/dhcp/dhcpd.leases
```

Untuk pencarian tertentu:

```bash
grep -n "lease" /var/lib/dhcp/dhcpd.leases
```

Informasi lease dapat membantu ketika ingin mengetahui:

- Client yang memperoleh IP.
- Alamat yang sedang digunakan.
- Status lease.
- Waktu lease.

---

## 11. DHCP Relay

### 11.1 Mengapa DHCP Relay Dibutuhkan?

DHCP pada tahap awal menggunakan broadcast.

Broadcast tidak secara otomatis diteruskan oleh router ke subnet lain.

Contoh:

```text
DHCP Client
192.168.2.0/24
       |
       |
     Router
       |
       |
DHCP Server
192.168.1.0/24
```

Client dan DHCP Server berada pada subnet yang berbeda.

Agar request DHCP dapat mencapai server, digunakan DHCP Relay.

---

### 11.2 Cara Kerja DHCP Relay

DHCP Relay menerima DHCP request dari client kemudian meneruskannya menuju DHCP Server.

Gambaran:

```text
Client
  |
  | DHCP Broadcast
  v
DHCP Relay
  |
  | Forward
  v
DHCP Server
  |
  | Response
  v
DHCP Relay
  |
  v
Client
```

DHCP Relay memungkinkan satu DHCP Server melayani beberapa subnet.

---

## 12. DHCP Relay Installation

Pada Debian-based environment:

```bash
apt update
apt install isc-dhcp-relay
```

Konfigurasi relay menyesuaikan interface dan DHCP Server yang digunakan.

Contoh struktur:

```conf
SERVERS="<DHCP-SERVER-IP>"
INTERFACES="<CLIENT-INTERFACE> <SERVER-INTERFACE>"
OPTIONS=""
```

Pastikan:

- Alamat DHCP Server benar.
- Interface menuju client benar.
- Interface menuju jaringan server benar.

---

## 13. IP Forwarding

Router atau relay yang menghubungkan jaringan berbeda harus dapat meneruskan packet.

Periksa:

```bash
sysctl net.ipv4.ip_forward
```

Jika hasilnya:

```text
net.ipv4.ip_forward = 0
```

IP forwarding belum aktif.

Untuk mengaktifkan sementara:

```bash
sysctl -w net.ipv4.ip_forward=1
```

Periksa kembali:

```bash
sysctl net.ipv4.ip_forward
```

Untuk konfigurasi persisten, parameter dapat disimpan pada:

```text
/etc/sysctl.conf
```

Kemudian konfigurasi diterapkan kembali sesuai mekanisme sistem.

---

## 14. Fixed Address

Tidak semua client harus mendapatkan IP secara dinamis.

DHCP juga dapat memberikan IP tertentu kepada client berdasarkan MAC Address.

Konsep:

```text
MAC Address
     |
     v
DHCP Reservation
     |
     v
Fixed IP Address
```

Contoh struktur:

```conf
host <CLIENT-NAME> {
    hardware ethernet <MAC-ADDRESS>;
    fixed-address <FIXED-IP>;
}
```

Fixed Address berbeda dengan static IP.

```text
Static IP
Client mengatur IP secara manual

Fixed Address
DHCP Server menentukan IP berdasarkan identitas client
```

Dengan fixed address, client tetap menggunakan DHCP untuk memperoleh konfigurasi, tetapi alamat yang diterima dapat ditentukan sebelumnya oleh administrator.

---

## 15. Verifikasi DHCP Server

### 15.1 Memeriksa Interface

```bash
ip addr
```

Pastikan interface:

- Aktif.
- Memiliki IP yang sesuai.
- Terhubung ke jaringan yang benar.

---

### 15.2 Memeriksa Routing

```bash
ip route
```

Periksa default route serta route jaringan internal.

---

### 15.3 Memeriksa Service

```bash
systemctl status isc-dhcp-server
```

Untuk pemeriksaan singkat:

```bash
systemctl is-active isc-dhcp-server
```

Untuk mengetahui apakah service aktif ketika boot:

```bash
systemctl is-enabled isc-dhcp-server
```

---

### 15.4 Memeriksa Konfigurasi

Sebelum melakukan restart service, periksa konfigurasi:

```bash
dhcpd -t
```

Jika ditemukan error, perbaiki konfigurasi terlebih dahulu.

Jangan melanjutkan pengujian hanya dengan asumsi bahwa konfigurasi sudah benar.

---

## 16. Packet Capture

### 16.1 tcpdump

DHCP dapat diamati menggunakan `tcpdump`.

```bash
tcpdump -i <INTERFACE> -n port 67 or port 68
```

Filter tersebut digunakan untuk melihat traffic DHCP pada UDP port 67 dan 68.

---

### 16.2 Wireshark

Capture packet dapat dianalisis menggunakan Wireshark.

Filter yang dapat digunakan:

```text
dhcp
```

atau:

```text
bootp
```

Karena DHCP menggunakan format message yang berasal dari BOOTP, Wireshark dapat menampilkan packet DHCP menggunakan protocol tree BOOTP/DHCP.

---

## 17. Analisis DORA

Saat melakukan capture, identifikasi:

```text
DHCPDISCOVER
       ↓
DHCPOFFER
       ↓
DHCPREQUEST
       ↓
DHCPACK
```

Perhatikan:

### DHCPDISCOVER

Client mencari DHCP Server.

### DHCPOFFER

Server menawarkan konfigurasi.

### DHCPREQUEST

Client memilih dan meminta konfigurasi.

### DHCPACK

Server mengonfirmasi konfigurasi.

Selain message type, perhatikan juga:

- Transaction ID.
- Client MAC Address.
- Requested IP Address.
- Server Identifier.
- Lease Time.
- DHCP Options.

Transaction ID dapat digunakan untuk menghubungkan packet yang berasal dari proses DHCP yang sama.

---

## 18. Troubleshooting DHCP

Ketika client tidak mendapatkan IP Address, jangan langsung mengganti konfigurasi secara acak.

Gunakan urutan pemeriksaan berikut:

```text
Client tidak mendapat IP
          |
          v
Periksa Interface
          |
          v
Periksa Koneksi
          |
          v
Periksa DHCP Service
          |
          v
Periksa Konfigurasi
          |
          v
Periksa Network dan Range
          |
          v
Periksa Relay
          |
          v
Periksa IP Forwarding
          |
          v
Capture Packet
          |
          v
Analisis DORA
```

---

### 18.1 Interface

Periksa:

```bash
ip link
```

Pastikan interface berada dalam kondisi aktif.

---

### 18.2 IP Server

Periksa:

```bash
ip addr
```

Pastikan server berada pada jaringan yang benar.

---

### 18.3 DHCP Configuration

Periksa konfigurasi:

```bash
dhcpd -t
```

Kemudian periksa kembali:

```text
Network
Netmask
Range
Gateway
DNS
Lease Time
```

---

### 18.4 DHCP Service

Periksa:

```bash
systemctl status isc-dhcp-server
```

Perhatikan error yang diberikan service.

---

### 18.5 Packet Capture

Jika konfigurasi terlihat benar tetapi client tetap tidak mendapatkan IP, lakukan packet capture.

```bash
tcpdump -i <INTERFACE> -n port 67 or port 68
```

Kemudian jawab pertanyaan berikut:

```text
Apakah DHCPDISCOVER muncul?

Apakah DHCPOFFER muncul?

Apakah DHCPREQUEST muncul?

Apakah DHCPACK muncul?
```

Dari urutan tersebut, titik kegagalan dapat dipersempit.

---

## 19. Troubleshooting DHCP Relay

Jika menggunakan DHCP Relay, periksa komunikasi pada setiap bagian:

```text
Client
  |
  v
Interface Client
  |
  v
DHCP Relay
  |
  v
IP Forwarding
  |
  v
Interface Server
  |
  v
DHCP Server
```

Periksa IP forwarding:

```bash
sysctl net.ipv4.ip_forward
```

Periksa konfigurasi relay dan pastikan alamat server benar.

Packet capture dapat dilakukan pada:

- Sisi client.
- Sisi relay.
- Sisi server.

Tujuannya adalah mengetahui apakah packet berhenti di client, relay, atau server.

---

## 20. Persistence

Konfigurasi yang berhasil sebelum restart belum tentu tetap berjalan setelah node melakukan restart.

Service DHCP harus diatur agar berjalan secara otomatis.

Periksa:

```bash
systemctl is-enabled isc-dhcp-server
```

Jika belum aktif:

```bash
systemctl enable isc-dhcp-server
```

Setelah melakukan restart, periksa:

```bash
systemctl status isc-dhcp-server
```

Kemudian lakukan pengujian ulang pada client:

```bash
ip addr
ip route
```

Jika menggunakan DHCP Relay, periksa juga service relay setelah restart.

---

## 21. Checklist Verifikasi

Gunakan checklist berikut selama proses pengerjaan:

| Komponen | Perintah / Metode |
|---|---|
| Interface | `ip addr` |
| Link | `ip link` |
| Routing | `ip route` |
| DHCP configuration | `dhcpd -t` |
| DHCP service | `systemctl status isc-dhcp-server` |
| Service enabled | `systemctl is-enabled isc-dhcp-server` |
| Client IP | `ip addr` |
| Client route | `ip route` |
| DHCP lease | `/var/lib/dhcp/dhcpd.leases` |
| IP forwarding | `sysctl net.ipv4.ip_forward` |
| DHCP packet | `tcpdump` |
| Packet analysis | Wireshark |
| DORA | DHCP packet analysis |
| Fixed Address | MAC Address + assigned IP |
| Persistence | Restart / reboot test |

---

## 22. Alur Belajar

Urutan pembelajaran DHCP pada praktikum ini adalah:

```text
DHCP Concept
      ↓
DHCP Message
      ↓
DORA
      ↓
DHCP Server
      ↓
DHCP Range
      ↓
DHCP Options
      ↓
DHCP Client
      ↓
Lease Time
      ↓
Packet Analysis
      ↓
DHCP Relay
      ↓
Fixed Address
      ↓
Troubleshooting
      ↓
Persistence
```

Praktikan disarankan memahami setiap tahap sebelum melanjutkan ke tahap berikutnya.

---

## 23. Kompetensi yang Harus Dikuasai

Setelah menyelesaikan materi ini, praktikan setidaknya harus mampu:

### Konsep

- Menjelaskan fungsi DHCP.
- Menjelaskan hubungan DHCP Client dan DHCP Server.
- Menjelaskan UDP port 67 dan 68.
- Menjelaskan proses DORA.
- Menjelaskan DHCP Lease.

### Konfigurasi

- Menentukan network dan subnet DHCP.
- Menentukan DHCP Range.
- Menentukan gateway.
- Menentukan DNS Server.
- Mengatur lease time.
- Mengonfigurasi DHCP Server.
- Mengonfigurasi DHCP Client.
- Mengonfigurasi DHCP Relay.
- Mengonfigurasi Fixed Address.

### Analisis

- Membaca DHCP packet.
- Menemukan DORA pada Wireshark.
- Mengidentifikasi Client MAC Address.
- Mengidentifikasi IP Address yang ditawarkan.
- Mengidentifikasi server DHCP.
- Membaca DHCP Options.

### Troubleshooting

- Memeriksa interface.
- Memeriksa service.
- Memeriksa konfigurasi.
- Memeriksa subnet dan range.
- Memeriksa relay.
- Memeriksa IP forwarding.
- Menganalisis packet untuk menemukan titik kegagalan.

### Persistence

- Memastikan service aktif.
- Memastikan service autostart.
- Memastikan konfigurasi tetap tersedia setelah restart.
- Melakukan pengujian kembali setelah node direstart.

---

## 24. Catatan Implementasi

Contoh konfigurasi pada materi ini menggunakan placeholder seperti:

```text
<NETWORK>
<NETMASK>
<START-IP>
<END-IP>
<GATEWAY>
<DNS-SERVER>
<MAC-ADDRESS>
<CLIENT-INTERFACE>
<DHCP-SERVER-IP>
```

Placeholder tersebut sengaja digunakan agar praktikan memahami hubungan antarparameter tanpa bergantung pada satu konfigurasi tertentu.

Sebelum melakukan konfigurasi, tentukan terlebih dahulu:

1. Network Address.
2. Subnet Mask.
3. DHCP Range.
4. Gateway.
5. DNS Server.
6. Interface Server.
7. Interface Client.
8. Interface Relay jika digunakan.
9. Lease Time.
10. MAC Address untuk Fixed Address.

Jangan menentukan nilai secara acak. Setiap parameter harus sesuai dengan topologi dan kebutuhan jaringan.

---

## 25. Referensi

1. R. Droms, **RFC 2131: Dynamic Host Configuration Protocol**  
   https://www.rfc-editor.org/rfc/rfc2131

2. S. Alexander dan R. Droms, **RFC 2132: DHCP Options and BOOTP Vendor Extensions**  
   https://www.rfc-editor.org/rfc/rfc2132

3. Internet Systems Consortium, **ISC DHCP**  
   https://www.isc.org/dhcp/

4. Internet Systems Consortium, **ISC DHCP End of Life Dates**  
   https://kb.isc.org/docs/isc-dhcp-eol-dates

5. Internet Systems Consortium, **Kea DHCP**  
   https://www.isc.org/kea/

---

## 26. Catatan

Materi ini digunakan sebagai panduan pembelajaran dan implementasi DHCP pada praktikum Komunikasi Data dan Jaringan Komputer.

Praktikan tetap harus memahami setiap konfigurasi yang dibuat, melakukan verifikasi, dan mampu menjelaskan hasil konfigurasi pada saat demo.
