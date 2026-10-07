# 1. Dynamic Host Configuration Protocol (DHCP)

## Daftar Isi

- [1.1 Konsep](#11-konsep)
  - [1.1.1 Pendahuluan](#111-pendahuluan)
  - [1.1.2 Apa itu DHCP?](#112-apa-itu-dhcp)
  - [1.1.3 DHCP Message](#113-dhcp-message)
  - [1.1.4 Proses DORA](#114-proses-dora)
  - [1.1.5 DHCP Relay](#115-dhcp-relay)
  - [1.1.6 DHCP Lease Time](#116-dhcp-lease-time)
- [1.2 Implementasi](#12-implementasi)
  - [1.2.1 Instalasi ISC DHCP Server](#121-instalasi-isc-dhcp-server)
  - [1.2.2 Konfigurasi Interface DHCP Server](#122-konfigurasi-interface-dhcp-server)
  - [1.2.3 Konfigurasi DHCP Pool](#123-konfigurasi-dhcp-pool)
  - [1.2.4 Konfigurasi DHCP Relay](#124-konfigurasi-dhcp-relay)
  - [1.2.5 Konfigurasi DHCP Client](#125-konfigurasi-dhcp-client)
  - [1.2.6 Pengujian DORA](#126-pengujian-dora)
  - [1.2.7 Lease Time](#127-lease-time)
  - [1.2.8 Fixed Address](#128-fixed-address)
  - [1.2.9 Pengujian End-to-End](#129-pengujian-end-to-end)
- [1.3 Latihan](#13-latihan)
- [1.4 Troubleshooting](#14-troubleshooting)
- [1.5 Referensi](#15-referensi)

---

# 1.1 Konsep

## 1.1.1 Pendahuluan

Pada praktikum sebelumnya, konfigurasi `IP Address`, `gateway`, `netmask`, dan `nameserver` dapat dilakukan secara manual. Cara tersebut masih masuk akal ketika jumlah host sedikit.

Masalah muncul ketika jumlah host semakin banyak. Bayangkan administrator harus memberikan IP secara manual ke puluhan atau ratusan perangkat. Selain melelahkan, cara tersebut juga meningkatkan risiko salah konfigurasi dan konflik alamat IP.

DHCP membantu menyederhanakan proses tersebut. Administrator cukup menyiapkan server dan aturan pembagian alamat, sedangkan client meminta konfigurasi jaringan secara otomatis.

---

## 1.1.2 Apa itu DHCP?

**Dynamic Host Configuration Protocol (DHCP)** adalah protokol client-server yang digunakan untuk memberikan konfigurasi jaringan kepada host secara otomatis.

Konfigurasi yang dapat diberikan oleh DHCP antara lain:

- `IP Address`
- `Subnet Mask`
- `Default Gateway`
- `DNS Server`
- `Lease Time`

Untuk DHCPv4, server menggunakan UDP port `67`, sedangkan client menggunakan UDP port `68`.

> Tidak perlu menghafalkan seluruh detail protokol pada tahap awal. Fokus utama praktikum adalah memahami hubungan antara **DHCP Server**, **DHCP Client**, dan **DHCP Relay**, kemudian membuktikan prosesnya melalui konfigurasi dan capture jaringan.

---

## 1.1.3 DHCP Message

Beberapa DHCP message yang perlu dikenal:

| Message | Fungsi sederhana |
|---|---|
| `DHCPDISCOVER` | Client mencari DHCP Server |
| `DHCPOFFER` | Server menawarkan konfigurasi |
| `DHCPREQUEST` | Client meminta konfigurasi yang dipilih |
| `DHCPACK` | Server mengonfirmasi konfigurasi |
| `DHCPNAK` | Server menolak request |
| `DHCPDECLINE` | Client menolak alamat yang ditawarkan karena konflik |
| `DHCPRELEASE` | Client melepaskan lease |

RFC 2131 menjelaskan fungsi message-message tersebut dan state machine DHCP client/server.

Referensi: https://www.rfc-editor.org/rfc/rfc2131

---

## 1.1.4 Proses DORA

Saat client belum memiliki konfigurasi DHCP yang dapat digunakan, proses normal memperoleh alamat dapat disederhanakan menjadi **DORA**:

```text
Client                             DHCP Server
  |                                      |
  |-------- DHCPDISCOVER --------------->|
  |<------- DHCPOFFER --------------------|
  |-------- DHCPREQUEST ----------------->|
  |<------- DHCPACK -----------------------|
```

Cara mudah mengingatnya:

> **Discover → Offer → Request → Acknowledge**

### DHCPDISCOVER

Client mengirimkan request untuk mencari DHCP Server.

### DHCPOFFER

DHCP Server memberikan penawaran berupa IP Address dan parameter jaringan lainnya.

### DHCPREQUEST

Client memilih penawaran dan meminta penggunaan konfigurasi tersebut.

### DHCPACK

DHCP Server mengonfirmasi konfigurasi. Setelah proses ini selesai, client dapat menggunakan konfigurasi yang diterima.

### Visualisasi

![Ilustrasi proses DHCP](https://raw.githubusercontent.com/lab-kcks/Modul-Komdat-Jarkom/77d7f496af24869ed9761e20e1c448aca55bec33/Modul-3/DHCP/images/DHCP.gif)

> **Catatan aset:** gambar pada modul versi lama berasal dari repository Modul-Komdat-Jarkom sebelumnya. Untuk repository final kalian, aset gambar sebaiknya dipindahkan ke folder `DHCP/images/` agar modul tidak bergantung pada repository lain.

---

## 1.1.5 DHCP Relay

Pada awal proses DHCP, client dapat menggunakan broadcast untuk mencari DHCP Server. Broadcast tidak diteruskan oleh router secara otomatis.

Masalahnya muncul ketika DHCP Client dan DHCP Server berada di **subnet yang berbeda**.

Di sinilah DHCP Relay dibutuhkan.

```text
+----------------+        +----------------+        +----------------+
| DHCP Client    |        | Router / Relay |        | DHCP Server    |
| Subnet A       | -----> |                | -----> | Subnet B       |
+----------------+        +----------------+        +----------------+
```

Relay bertindak sebagai **perantara**, bukan sebagai DHCP Server.

Secara sederhana:

```text
DHCPDISCOVER
Client → Relay → Server

DHCPOFFER
Server → Relay → Client
```

Relay memungkinkan satu DHCP Server melayani beberapa subnet tanpa harus menempatkan satu DHCP Server pada setiap subnet.

![Ilustrasi DHCP Relay](https://raw.githubusercontent.com/lab-kcks/Modul-Komdat-Jarkom/77d7f496af24869ed9761e20e1c448aca55bec33/Modul-3/DHCP/images/relay.png)

---

## 1.1.6 DHCP Lease Time

IP dari DHCP bukan selalu bersifat permanen. Ketika client mendapatkan IP, server memberikan **lease**.

Lease menentukan berapa lama client dapat menggunakan alamat tersebut sebelum harus melakukan renewal atau memperoleh lease baru.

Pada konfigurasi ISC DHCP:

- `default-lease-time` = lease default dalam **detik**;
- `max-lease-time` = batas maksimum lease dalam **detik**.

Contoh:

```conf
default-lease-time 600;
max-lease-time 7200;
```

Artinya lease default adalah 600 detik dan maksimum 7200 detik.

---

# 1.2 Implementasi

## 1.2.1 Instalasi ISC DHCP Server

> **Catatan software:** ISC DHCP tetap digunakan karena mengikuti baseline praktikum sebelumnya. ISC menyatakan ISC DHCP telah mencapai **End of Life** pada 2022 dan merekomendasikan Kea untuk deployment baru. Praktikum ini tidak dimaksudkan sebagai konfigurasi production.

Pada node yang digunakan sebagai DHCP Server:

```bash
apt-get update
apt-get install isc-dhcp-server -y
```

Periksa instalasi:

```bash
dhcpd --version
```

Pastikan command menampilkan versi `dhcpd`.

---

## 1.2.2 Konfigurasi Interface DHCP Server

Sebelum memilih interface, periksa terlebih dahulu:

```bash
ip -br a
```

Perhatikan interface yang terhubung ke jaringan client.

Buka konfigurasi:

```bash
nano /etc/default/isc-dhcp-server
```

Contoh jika interface client adalah `eth0`:

```text
INTERFACESv4="eth0"
```

> **Jangan menyalin `eth0` secara mentah.** Pastikan interface yang digunakan sesuai topologi kelompok kalian.

---

## 1.2.3 Konfigurasi DHCP Pool

Buka konfigurasi utama:

```bash
nano /etc/dhcp/dhcpd.conf
```

Gunakan `[PREFIX]` sebagai placeholder. Contoh berikut menggunakan dua subnet seperti pola praktikum sebelumnya.

```conf
subnet [PREFIX].1.0 netmask 255.255.255.0 {
    range [PREFIX].1.100 [PREFIX].1.200;
    option subnet-mask 255.255.255.0;
    option routers [PREFIX].1.1;
    option broadcast-address [PREFIX].1.255;
    option domain-name-servers [DNS_SERVER_IP];
    default-lease-time 600;
    max-lease-time 7200;
}

subnet [PREFIX].2.0 netmask 255.255.255.0 {
    range [PREFIX].2.100 [PREFIX].2.200;
    option subnet-mask 255.255.255.0;
    option routers [PREFIX].2.1;
    option broadcast-address [PREFIX].2.255;
    option domain-name-servers [DNS_SERVER_IP];
    default-lease-time 600;
    max-lease-time 7200;
}
```

### Apa arti setiap parameter?

| Parameter | Fungsi |
|---|---|
| `subnet` | Menentukan jaringan yang dilayani DHCP |
| `netmask` | Menentukan subnet mask |
| `range` | Rentang IP dinamis yang dapat dipinjam client |
| `option routers` | Default gateway yang diberikan ke client |
| `option broadcast-address` | Broadcast address subnet |
| `option domain-name-servers` | DNS server yang diberikan ke client |
| `default-lease-time` | Durasi lease default, dalam detik |
| `max-lease-time` | Durasi lease maksimum, dalam detik |

### Validasi konfigurasi

Sebelum restart service, periksa syntax:

```bash
dhcpd -t -cf /etc/dhcp/dhcpd.conf
```

Jika tidak terdapat pesan error syntax, lanjutkan:

```bash
service isc-dhcp-server restart
```

Periksa status:

```bash
service isc-dhcp-server status
```

Jika service gagal start, **jangan langsung mengubah konfigurasi**. Gunakan bagian [Troubleshooting](#14-troubleshooting).

---

## 1.2.4 Konfigurasi DHCP Relay

DHCP Relay digunakan ketika DHCP Server dan DHCP Client berada di subnet berbeda.

Pada router yang bertugas sebagai DHCP Relay:

```bash
apt-get update
apt-get install isc-dhcp-relay -y
```

Buka konfigurasi:

```bash
nano /etc/default/isc-dhcp-relay
```

Isi sesuai topologi:

```text
SERVERS="[IP_DHCP_SERVER]"
INTERFACES="[INTERFACE_KE_CLIENT] [INTERFACE_KE_SERVER]"
OPTIONS=""
```

### IP forwarding

Edit:

```bash
nano /etc/sysctl.conf
```

Pastikan ada:

```text
net.ipv4.ip_forward=1
```

Terapkan:

```bash
sysctl -p
```

Cek:

```bash
cat /proc/sys/net/ipv4/ip_forward
```

Target:

```text
1
```

Restart relay:

```bash
service isc-dhcp-relay restart
service isc-dhcp-relay status
```

### Verifikasi konsep

Jika DHCP Server dan Client berada pada subnet yang sama, relay **tidak diperlukan**.

Jika keduanya berada pada subnet berbeda, relay diperlukan agar pesan DHCP dapat diteruskan antar-subnet.

---

## 1.2.5 Konfigurasi DHCP Client

Pada client yang akan menerima IP secara otomatis:

```bash
nano /etc/network/interfaces
```

Ubah konfigurasi interface menjadi:

```text
auto eth0
iface eth0 inet dhcp
```

Pastikan konfigurasi statis yang sebelumnya digunakan pada interface tersebut sudah tidak aktif.

Restart node melalui GNS3, lalu periksa:

```bash
ip -br a
```

Kemudian:

```bash
ip route
```

dan:

```bash
cat /etc/resolv.conf
```

Client seharusnya mendapatkan:

- IP dari DHCP pool;
- default gateway yang dikirim DHCP Server;
- DNS server yang dikirim DHCP Server, jika dikonfigurasi.

---

## 1.2.6 Pengujian DORA

Untuk melihat proses DHCP secara langsung, gunakan Wireshark.

### Langkah

1. Buka Wireshark pada interface yang sesuai.
2. Mulai capture.
3. Pastikan client melakukan proses DHCP/renew.
4. Gunakan display filter:

```text
bootp
```

5. Cari urutan:

```text
DHCPDISCOVER
DHCPOFFER
DHCPREQUEST
DHCPACK
```

Wireshark menggunakan `bootp` sebagai filter untuk trafik DHCP/BOOTP.

![DHCP Message Header](https://raw.githubusercontent.com/lab-kcks/Modul-Komdat-Jarkom/77d7f496af24869ed9761e20e1c448aca55bec33/Modul-3/DHCP/images/DHCP-message-header.png)

### Yang perlu dapat dijelaskan praktikan

> **Mengapa DHCPDISCOVER dapat berupa broadcast?**
>
> Karena client belum mengetahui DHCP Server mana yang tersedia dan belum memiliki konfigurasi IP yang dapat digunakan untuk komunikasi normal.

> **Mengapa router biasa tidak meneruskan broadcast tersebut?**
>
> Karena broadcast dibatasi pada broadcast domain. DHCP Relay digunakan untuk menjembatani kebutuhan tersebut ketika server berada di subnet lain.

---

## 1.2.7 Lease Time

Untuk mempermudah pengamatan pada praktikum, lease dapat dibuat singkat.

Contoh:

```conf
default-lease-time 120;
max-lease-time 120;
```

Setelah perubahan:

```bash
service isc-dhcp-server restart
```

Periksa lease yang tercatat:

```bash
cat /var/lib/dhcp/dhcpd.leases
```

> Gunakan nilai lease singkat hanya untuk pengujian. Untuk konfigurasi normal, sesuaikan lease dengan kebutuhan jaringan.

### Apa yang perlu diamati?

- client memperoleh lease;
- client melakukan renewal ketika diperlukan;
- lease tercatat pada DHCP Server;
- alamat dapat kembali digunakan ketika lease sudah tidak berlaku sesuai mekanisme DHCP.

---

## 1.2.8 Fixed Address

Tidak semua client harus mendapatkan IP yang berubah-ubah. Perangkat tertentu dapat membutuhkan alamat yang tetap, misalnya server, printer, atau perangkat yang harus mudah dikenali.

Salah satu pendekatannya adalah memberikan **Fixed Address berdasarkan MAC Address**.

### Langkah 1 — Cari MAC Address client

Pada client:

```bash
ip link show eth0
```

Cari nilai:

```text
link/ether XX:XX:XX:XX:XX:XX
```

### Langkah 2 — Tambahkan host declaration

Pada DHCP Server:

```bash
nano /etc/dhcp/dhcpd.conf
```

Tambahkan:

```conf
host client-fixed {
    hardware ethernet [MAC_CLIENT];
    fixed-address [PREFIX].2.123;
}
```

Contoh format MAC:

```conf
hardware ethernet 02:42:aa:bb:cc:dd;
```

> Gunakan **MAC Address asli client**. Jangan menyalin MAC dari contoh modul.

Restart DHCP Server:

```bash
service isc-dhcp-server restart
```

Restart client dari GNS3 dan periksa:

```bash
ip -br a
```

Client yang telah dipetakan seharusnya memperoleh alamat fixed yang telah ditentukan.

---

## 1.2.9 Pengujian End-to-End

Setelah seluruh konfigurasi selesai, lakukan pengujian dari sisi client.

### Pengujian 1 — IP

```bash
ip -br a
```

Pastikan IP masuk dalam pool atau fixed address yang telah ditentukan.

### Pengujian 2 — Gateway

```bash
ip route
```

Pastikan terdapat default route menuju gateway yang diberikan DHCP.

### Pengujian 3 — DNS

```bash
cat /etc/resolv.conf
```

Pastikan nameserver sesuai konfigurasi DHCP.

### Pengujian 4 — Koneksi

```bash
ping -c 3 [IP_GATEWAY]
```

Jika topologi memungkinkan akses Internet:

```bash
ping -c 3 8.8.8.8
```

Kemudian uji resolusi nama:

```bash
ping -c 3 google.com
```

### Pengujian 5 — Packet Capture

Gunakan Wireshark dengan filter:

```text
bootp
```

Pastikan praktikan mampu menunjukkan proses DORA.

---

# 1.3 Latihan

## Latihan 1 — DHCP Pool dan Lease Time

Buat konfigurasi DHCP agar client mendapatkan IP dari rentang berikut:

```text
[PREFIX].1.69  - [PREFIX].1.70
[PREFIX].1.200 - [PREFIX].1.225
```

Ketentuan:

- lease time = `120` detik;
- DNS diarahkan ke DNS Server praktikum;
- client tetap dapat menggunakan gateway;
- client dapat mengakses Internet apabila routing/NAT pada topologi telah disiapkan.

### Bukti yang perlu ditunjukkan

```text
[ ] IP client masuk dalam range
[ ] Gateway benar
[ ] DNS benar
[ ] Lease time aktif
[ ] DORA terlihat di Wireshark
```

---

## Latihan 2 — DHCP Relay

Tempatkan DHCP Server dan client pada subnet berbeda.

Konfigurasi DHCP Relay sehingga client tetap mendapatkan IP.

### Bukti yang perlu ditunjukkan

```text
[ ] Client memperoleh IP
[ ] DHCP Relay aktif
[ ] IP forwarding aktif
[ ] DORA berhasil
[ ] Praktikan dapat menjelaskan peran relay
```

---

## Latihan 3 — Fixed Address

Pilih salah satu client dan tentukan:

```text
MAC Address → Fixed IP
```

Gunakan format:

```text
[PREFIX].2.123
```

Setelah client direstart, IP harus tetap mengikuti pemetaan MAC Address tersebut.

---

## Latihan 4 — Analisis Paket DHCP

Lakukan capture ketika client meminta alamat baru.

Gunakan filter:

```text
bootp
```

Kemudian jawab:

1. Paket mana yang merupakan `DHCPDISCOVER`?
2. Siapa pengirim dan penerima `DHCPOFFER`?
3. Pada paket mana client meminta alamat yang ditawarkan?
4. Paket mana yang menunjukkan server menerima request?
5. Mengapa fase awal DHCP menggunakan broadcast?
6. Mengapa DHCP Relay dibutuhkan ketika server berbeda subnet?

---

# 1.4 Troubleshooting

## 1.4.1 Service `isc-dhcp-server` gagal start

Periksa status:

```bash
service isc-dhcp-server status
```

Periksa syntax:

```bash
dhcpd -t -cf /etc/dhcp/dhcpd.conf
```

Periksa log:

```bash
journalctl -u isc-dhcp-server --no-pager -n 50
```

Kesalahan paling umum:

- salah syntax pada `dhcpd.conf`;
- interface pada `INTERFACESv4` tidak sesuai;
- subnet declaration tidak sesuai dengan interface server;
- range IP berada di luar subnet yang didefinisikan.

---

## 1.4.2 Client tidak memperoleh IP

Periksa client:

```bash
ip -br a
```

Periksa DHCP Server:

```bash
service isc-dhcp-server status
ss -lunp | grep ':67'
```

Lalu lakukan capture Wireshark dengan:

```text
bootp
```

Interpretasi cepat:

```text
Tidak ada DHCPDISCOVER
→ cek client/interface/link

Ada DISCOVER tetapi tidak ada OFFER
→ cek DHCP Server / Relay / pool

Ada OFFER tetapi tidak ada REQUEST
→ cek client

Ada REQUEST tetapi tidak ada ACK
→ cek DHCP Server / konfigurasi pool
```

---

## 1.4.3 Client mendapat IP tetapi tidak dapat Internet

DHCP berhasil belum tentu Internet langsung berhasil.

Periksa:

```bash
ip route
```

Pastikan default gateway tersedia.

Kemudian:

```bash
ping -c 3 [IP_GATEWAY]
ping -c 3 8.8.8.8
```

Jika IP Internet dapat diping tetapi domain tidak dapat di-resolve:

```bash
cat /etc/resolv.conf
```

Masalah kemungkinan berada pada DNS, bukan DHCP address assignment.

---

## 1.4.4 Relay tidak bekerja

Periksa:

```bash
cat /etc/default/isc-dhcp-relay
cat /proc/sys/net/ipv4/ip_forward
service isc-dhcp-relay status
```

Target:

```text
net.ipv4.ip_forward = 1
```

Pastikan `SERVERS` menunjuk ke IP DHCP Server dan `INTERFACES` mencakup interface yang diperlukan untuk proses relay.

---

## 1.4.5 Fixed Address tidak sesuai

Periksa MAC client:

```bash
ip link show eth0
```

Bandingkan dengan:

```conf
host client-fixed {
    hardware ethernet [MAC_CLIENT];
    fixed-address [PREFIX].2.123;
}
```

Jika MAC berbeda, DHCP Server tidak akan mencocokkan client dengan host declaration tersebut.

---

# 1.5 Referensi

- RFC 2131 — Dynamic Host Configuration Protocol: https://www.rfc-editor.org/rfc/rfc2131
- RFC 2132 — DHCP Options and BOOTP Vendor Extensions: https://www.rfc-editor.org/rfc/rfc2132
- Wireshark DHCP / BOOTP: https://wiki.wireshark.org/DHCP
- ISC DHCP: https://www.isc.org/dhcp/
- ISC Kea: https://www.isc.org/kea/
- Modul Komdat Jarkom tahun sebelumnya: https://github.com/lab-kcks/Modul-Komdat-Jarkom/tree/77d7f496af24869ed9761e20e1c448aca55bec33/Modul-3/DHCP
