# Modul 3 — Dynamic Host Configuration Protocol (DHCP)

> **Praktikum Komunikasi Data & Jaringan Komputer**
>
> Modul ini mempertahankan alur utama materi DHCP dari modul tahun sebelumnya. Perubahan utama pada versi ini adalah penyusunan panduan yang lebih terarah, penggunaan **IP Prefix kelompok** sebagai placeholder konfigurasi, serta penambahan langkah verifikasi, analisis paket, dan troubleshooting agar praktikan tidak hanya mengikuti konfigurasi tetapi memahami hasilnya.

---

## Daftar Isi

- [0. Gambaran Modul](#0-gambaran-modul)
- [1. Prasyarat](#1-prasyarat)
- [2. Konvensi IP Prefix](#2-konvensi-ip-prefix)
- [3. Alur Praktikum DHCP](#3-alur-praktikum-dhcp)
- [4. Checkpoint](#4-checkpoint)
- [5. Troubleshooting Awal](#5-troubleshooting-awal)
- [6. Materi DHCP](#6-materi-dhcp)
- [7. Referensi](#7-referensi)

---

# 0. Gambaran Modul

Pada praktikum sebelumnya, konfigurasi alamat IP, gateway, netmask, dan nameserver masih dapat dilakukan secara manual. Cara ini cukup untuk jaringan kecil, tetapi menjadi kurang praktis ketika jumlah host bertambah.

Pada modul ini, kita akan menggunakan **Dynamic Host Configuration Protocol (DHCP)** untuk memberikan konfigurasi jaringan kepada client secara otomatis.

Fokus pembelajaran modul ini adalah:

1. memahami konsep DHCP dan proses DORA;
2. membangun DHCP Server;
3. memahami dan mengonfigurasi DHCP Relay;
4. membuat client memperoleh konfigurasi jaringan secara otomatis;
5. memahami DHCP Lease Time;
6. membuat Fixed Address berdasarkan MAC Address;
7. membuktikan konfigurasi menggunakan Wireshark, log, dan command-line tools;
8. melakukan troubleshooting ketika client tidak memperoleh konfigurasi yang sesuai.

> **Catatan:** Bagian **Reverse Proxy** dikerjakan pada bagian/modul terpisah oleh penyusun lain. README ini hanya mencakup pengantar Modul 3 dan materi DHCP.

---

# 1. Prasyarat

Sebelum menjalankan praktikum DHCP, pastikan:

- project GNS3 dapat dibuka dan seluruh node yang dibutuhkan tersedia;
- koneksi antar-node sesuai dengan topologi praktikum;
- router dapat berfungsi sebagai penghubung antar-subnet;
- interface jaringan setiap node dapat dikenali dengan `ip -br a`;
- alamat IP yang digunakan mengikuti **IP Prefix kelompok**;
- client yang akan diuji dapat diubah dari konfigurasi statis menjadi DHCP;
- Wireshark tersedia untuk melakukan capture trafik DHCP.

Urutan troubleshooting sebaiknya selalu dimulai dari lapisan paling dasar:

```text
Interface
    ↓
IP / Subnet
    ↓
Gateway / Routing
    ↓
DHCP Server
    ↓
DHCP Relay
    ↓
DHCP Client
    ↓
DNS / Internet
```

Jika client belum mendapatkan IP, jangan langsung menyimpulkan bahwa DHCP Server rusak. Periksa terlebih dahulu apakah interface dan jalur jaringan menuju server memang tersedia.

---

# 2. Konvensi IP Prefix

Agar konfigurasi dapat digunakan oleh seluruh kelompok, contoh IP pada modul menggunakan placeholder berikut:

```text
[PREFIX].1.x
[PREFIX].2.x
```

Sebagai contoh, apabila prefix kelompok adalah `10.91`, maka:

```text
[PREFIX].1.1 → 10.91.1.1
[PREFIX].2.1 → 10.91.2.1
```

**Jangan menggunakan angka contoh secara mentah.** Ganti `[PREFIX]` dengan prefix kelompok kalian pada seluruh konfigurasi.

Contoh pola alamat:

```text
Subnet 1 : [PREFIX].1.0/24
Gateway  : [PREFIX].1.1

Subnet 2 : [PREFIX].2.0/24
Gateway  : [PREFIX].2.1
```

---

# 3. Alur Praktikum DHCP

Materi DHCP dikerjakan secara bertahap:

```text
Konsep DHCP
     ↓
DHCP Server
     ↓
DHCP Pool
     ↓
DHCP Relay
     ↓
DHCP Client
     ↓
DORA / Wireshark
     ↓
Lease Time
     ↓
Fixed Address
     ↓
End-to-End Testing
     ↓
Troubleshooting
     ↓
Latihan
```

Setiap bagian memiliki tiga tujuan sederhana:

> **Konfigurasi → Verifikasi → Jelaskan**

Praktikan dianggap memahami konfigurasi ketika mampu menunjukkan hasilnya dan menjelaskan mengapa hasil tersebut muncul.

---

# 4. Checkpoint

Sebelum berpindah ke bagian berikutnya, pastikan checkpoint berikut terpenuhi.

### Checkpoint A — Network

```text
[ ] Interface yang digunakan benar
[ ] IP dan subnet sesuai
[ ] Gateway dapat dijangkau
[ ] Routing antar-subnet berjalan
```

### Checkpoint B — DHCP Server

```text
[ ] isc-dhcp-server terpasang
[ ] interface DHCP benar
[ ] dhcpd.conf valid
[ ] DHCP Server aktif
```

### Checkpoint C — DHCP Client

```text
[ ] Client menggunakan DHCP
[ ] Client memperoleh IP dari pool
[ ] Gateway sesuai
[ ] DNS sesuai
```

### Checkpoint D — Analisis

```text
[ ] DORA dapat ditemukan di Wireshark
[ ] Lease tercatat di DHCP Server
[ ] Relay dapat melayani subnet berbeda
[ ] Fixed Address sesuai MAC Address
```

---

# 5. Troubleshooting Awal

Jika mengalami masalah, jangan langsung mengubah banyak konfigurasi sekaligus. Gunakan urutan pemeriksaan berikut.

### Pada node yang bermasalah

```bash
ip -br a
ip route
```

### Pada DHCP Server

```bash
service isc-dhcp-server status
dhcpd -t -cf /etc/dhcp/dhcpd.conf
journalctl -u isc-dhcp-server --no-pager -n 50
```

### Pada DHCP Relay

```bash
cat /etc/default/isc-dhcp-relay
cat /proc/sys/net/ipv4/ip_forward
service isc-dhcp-relay status
```

### Pada Wireshark

Gunakan display filter:

```text
bootp
```

Lalu cari urutan:

```text
DHCPDISCOVER → DHCPOFFER → DHCPREQUEST → DHCPACK
```

---

# 6. Materi DHCP

Silakan lanjut ke:

**[DHCP — Konsep, Implementasi, Testing, Troubleshooting, dan Latihan](./DHCP/README.md)**

---

# 7. Referensi

- RFC 2131 — Dynamic Host Configuration Protocol: https://www.rfc-editor.org/rfc/rfc2131
- RFC 2132 — DHCP Options and BOOTP Vendor Extensions: https://www.rfc-editor.org/rfc/rfc2132
- Wireshark DHCP: https://wiki.wireshark.org/DHCP
- ISC DHCP: https://www.isc.org/dhcp/
- ISC Kea: https://www.isc.org/kea/
