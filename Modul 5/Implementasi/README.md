# Implementasi Firewall

Pada bagian ini, praktikan menerapkan firewall secara langsung menggunakan GNS3. Seluruh konsep pada [materi Firewall](../Firewall/README.md) dicoba pada sebuah router Linux, dari rule paling sederhana sampai rule yang memakai waktu, NAT, dan status koneksi.

Implementasi menggunakan:

- `debinet` untuk `Firewall` (router) dan `Water7` (server), karena keduanya membutuhkan `iptables` dan `apt`
- `alpinet` untuk `Baratie`, `Mariejois`, dan `Arabasta` (PC)
- `iptables` sebagai firewall
- `nc` (netcat) sebagai alat uji koneksi TCP
- `ifupdown` (dipasang lewat `apt` pada `debinet`) agar konfigurasi interface tersimpan di `/etc/network/interfaces`

Implementasi ini menggantikan latihan berbasis Cisco Packet Tracer pada modul sebelumnya. Empat kebutuhan pada latihan lama dijalankan satu per satu sebagai skenario:

| Skenario | Kebutuhan | Teknik yang dipakai |
|---|---|---|
| 1 | PC Baratie tidak diizinkan mengakses server Water7 | `FORWARD` pada router |
| 2 | PC Arabasta tidak dapat diakses pada pukul 07.00 sampai 17.00 | `FORWARD` dengan match `time` |
| 3 | Server Water7 tidak diperbolehkan menerima koneksi HTTP | `INPUT` pada Water7, `DROP` dan `REJECT` |
| 4 | Semua paket yang menuju PC Baratie diarahkan ke PC Mariejois | DNAT pada `PREROUTING` |

Setelah keempatnya, bagian 10 membahas *default deny* dengan rule stateful, dan bagian 11 membahas cara menyimpan rule supaya tidak hilang saat node di-restart.

> **Catatan:** IP address pada contoh implementasi menggunakan `10.50.1.0/24`, `10.50.2.0/24`, dan `10.50.3.0/24` agar langkah lebih mudah diikuti. Jika kelompok kalian memiliki prefix sendiri, ganti seluruh alamat secara konsisten, termasuk pada rule iptables.

---

## Daftar Isi

- [1. Persiapan GNS3](#1-persiapan-gns3)
- [2. Konfigurasi Router Firewall](#2-konfigurasi-router-firewall)
- [3. Konfigurasi Host](#3-konfigurasi-host)
- [4. Pengujian Awal](#4-pengujian-awal)
- [5. Memahami INPUT, FORWARD, dan OUTPUT](#5-memahami-input-forward-dan-output)
- [6. Skenario 1: Memblokir Baratie ke Water7](#6-skenario-1-memblokir-baratie-ke-water7)
- [7. Skenario 2: Memblokir Arabasta pada Jam Tertentu](#7-skenario-2-memblokir-arabasta-pada-jam-tertentu)
- [8. Skenario 3: Water7 Menolak HTTP](#8-skenario-3-water7-menolak-http)
- [9. Skenario 4: Mengalihkan Baratie ke Mariejois dengan DNAT](#9-skenario-4-mengalihkan-baratie-ke-mariejois-dengan-dnat)
- [10. Default Deny dan Stateful Filtering](#10-default-deny-dan-stateful-filtering)

---

# 1. Persiapan GNS3

## 1.1 Topologi

Buat topologi berikut pada GNS3.

![Topologi implementasi firewall](img/01-topologi-gns3.png)

Gambaran logisnya:

```text
                               [NAT1]
                                  |
                                eth0
                          +--------------+
 [Baratie]                |              |
  10.50.1.2 ---+          |              |--eth2--- [Arabasta]
               |          |   Firewall   |          10.50.2.2
          [Switch1]--eth1-|              |
               |          |              |--eth3--- [Water7]
  10.50.1.3 ---+          |              |          10.50.3.2
 [Mariejois]              +--------------+

 Firewall:  eth1 = 10.50.1.1/24   eth2 = 10.50.2.1/24   eth3 = 10.50.3.1/24
```

Topologi terdiri dari:

| Node | Fungsi | Image |
|---|---|---|
| `NAT1` | Akses internet untuk instalasi package dan uji NAT | NAT GNS3 |
| `Firewall` | Router sekaligus firewall | `debinet` (4 network adapter) |
| `Switch1` | Menghubungkan dua PC pada LAN 1 | Ethernet switch |
| `Baratie` | PC pada LAN 1 | `alpinet` |
| `Mariejois` | PC pada LAN 1, tujuan DNAT pada skenario 4 | `alpinet` |
| `Arabasta` | PC pada LAN 2 | `alpinet` |
| `Water7` | Server pada LAN 3 | `debinet` |

`Switch1` dibutuhkan karena LAN 1 berisi dua host. LAN 2 dan LAN 3 masing-masing hanya berisi satu host, sehingga dihubungkan langsung ke router.

## 1.2 Pembagian Jaringan

| Jaringan | Network | Gateway | Isi |
|---|---|---|---|
| LAN 1 | `10.50.1.0/24` | `10.50.1.1` | Baratie, Mariejois |
| LAN 2 | `10.50.2.0/24` | `10.50.2.1` | Arabasta |
| LAN 3 | `10.50.3.0/24` | `10.50.3.1` | Water7 |

Alamat setiap node:

| Node | Interface | Mode | IP Address | Gateway |
|---|---|---|---|---|
| `Firewall` | `eth0` | DHCP | otomatis dari NAT | otomatis |
| | `eth1` | Static | `10.50.1.1/24` | - |
| | `eth2` | Static | `10.50.2.1/24` | - |
| | `eth3` | Static | `10.50.3.1/24` | - |
| `Baratie` | `eth0` | Static | `10.50.1.2/24` | `10.50.1.1` |
| `Mariejois` | `eth0` | Static | `10.50.1.3/24` | `10.50.1.1` |
| `Arabasta` | `eth0` | Static | `10.50.2.2/24` | `10.50.2.1` |
| `Water7` | `eth0` | Static | `10.50.3.2/24` | `10.50.3.1` |

## 1.3 Hubungan Interface

Setiap kabel pada topologi menghubungkan dua port. Tarik kabel persis sesuai tabel berikut.

| No | Dari | Port | Ke | Port |
|---|---|---|---|---|
| 1 | `Firewall` | `eth0` | `NAT1` | `nat0` |
| 2 | `Firewall` | `eth1` | `Switch1` | `Ethernet0` |
| 3 | `Switch1` | `Ethernet1` | `Baratie` | `eth0` |
| 4 | `Switch1` | `Ethernet2` | `Mariejois` | `eth0` |
| 5 | `Firewall` | `eth2` | `Arabasta` | `eth0` |
| 6 | `Firewall` | `eth3` | `Water7` | `eth0` |

Port pada `Switch1` bernama `Ethernet0`, `Ethernet1`, dan seterusnya (di kanvas GNS3 tampil sebagai `e0`, `e1`). Jika nama port pada GNS3 kalian berbeda, ikuti nama yang tampil.

Pastikan interface pada GNS3 sesuai dengan hasil `ip -br a` pada masing-masing node. Rule iptables pada modul ini menyebut nama interface (`eth1`, `eth3`, dan seterusnya), sehingga kabel yang tertukar akan membuat rule menyasar jaringan yang salah.

---

# 2. Konfigurasi Router Firewall

`Firewall` menghubungkan tiga LAN dan juga menjadi pintu keluar ke internet melalui `NAT1`.

## 2.1 Periksa Interface

Nyalakan node `Firewall`, buka console, lalu jalankan:

```bash
ip -br a
```

Pastikan terdapat `eth0`, `eth1`, `eth2`, dan `eth3`. Pada tahap ini `eth0` biasanya sudah mendapat IP dari NAT, sedangkan `eth1` sampai `eth3` belum memiliki alamat.

## 2.2 Beri IP pada Interface

Beri alamat dan nyalakan `eth1` sampai `eth3` dalam satu perintah:

```bash
for i in 1 2 3; do ip addr add 10.50.$i.1/24 dev eth$i; ip link set eth$i up; done
```

Jika `eth0` ternyata belum memiliki IP, isi secara manual:

```bash
ip link set eth0 up; ip addr add 192.168.122.100/24 dev eth0; ip route replace default via 192.168.122.1
```

Alamat `192.168.122.x` mengikuti jaringan bawaan NAT GNS3, sama seperti pada skrip router Modul 3. Sesuaikan jika NAT kalian memakai jaringan lain.

Verifikasi:

```bash
ip -br a
ip route
```

Hasil yang diharapkan: `eth1`, `eth2`, dan `eth3` berstatus `UP` dengan alamat `10.50.1.1/24`, `10.50.2.1/24`, dan `10.50.3.1/24`. Pada `ip route` terdapat satu route default (lewat `eth0`) dan tiga route jaringan lokal.

![Interface Firewall](img/02-ip-firewall.png)

## 2.3 Aktifkan IP Forwarding

Supaya paket dapat diteruskan antar-subnet, aktifkan forwarding:

```bash
sysctl -w net.ipv4.ip_forward=1
```

Periksa:

```bash
sysctl net.ipv4.ip_forward
```

Hasil yang diharapkan:

```text
net.ipv4.ip_forward = 1
```

## 2.4 Akses Internet, Instal Package, dan NAT

Pasang DNS resolver, lalu uji koneksi router ke internet:

```bash
echo "nameserver 8.8.8.8" > /etc/resolv.conf
ping -c 3 8.8.8.8
```

Instal package yang dibutuhkan:

```bash
apt update && apt install -y ifupdown iptables conntrack
```

Periksa versi iptables:

```bash
iptables --version
```

Keluarannya berakhiran `(nf_tables)` atau `(legacy)`. Keduanya dapat dipakai pada modul ini.

![iptables terpasang](img/03-iptables-version.png)

Aktifkan NAT agar host di belakang router dapat keluar ke internet:

```bash
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

Rule ini sama dengan yang dipakai pada Modul 1: alamat sumber paket yang keluar lewat `eth0` diganti dengan IP milik `eth0`, karena IP privat `10.50.x.x` tidak dikenal oleh jaringan di luar.

## 2.5 Simpan Konfigurasi Interface

Setelah `ifupdown` terpasang, tulis konfigurasi interface agar alamat tidak hilang saat node direstart:

```bash
cat > /etc/network/interfaces <<'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 10.50.1.1
    netmask 255.255.255.0

auto eth2
iface eth2 inet static
    address 10.50.2.1
    netmask 255.255.255.0

auto eth3
iface eth3 inet static
    address 10.50.3.1
    netmask 255.255.255.0
EOF
```

Uji bahwa file tersebut benar. Alamat dari bagian 2.2 dihapus dulu supaya `ifup` tidak menolak karena alamat sudah ada, lalu `ifup` memasangnya kembali dari file:

```bash
for i in 1 2 3; do ip addr flush dev eth$i; done
mkdir -p /run/network; ifup eth1 eth2 eth3
ip -br a
```

Hasil yang diharapkan: `eth1`, `eth2`, dan `eth3` kembali memiliki alamat `10.50.1.1/24`, `10.50.2.1/24`, dan `10.50.3.1/24`. `eth0` tidak ikut dijalankan ulang karena sudah aktif dan sudah dipakai untuk akses internet.

---

# 3. Konfigurasi Host

## 3.1 Baratie

Masuk ke console `Baratie`:

```bash
cat > /etc/network/interfaces <<'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.50.1.2
    netmask 255.255.255.0
    gateway 10.50.1.1
EOF
ifdown eth0 2>/dev/null; ifup eth0
ip -br a
ip route
```

Hasil yang diharapkan: `eth0` memiliki alamat `10.50.1.2/24`, dan route default mengarah ke `10.50.1.1`.

![Konfigurasi Baratie](img/04-ip-baratie.png)

## 3.2 Mariejois

Masuk ke console `Mariejois`:

```bash
cat > /etc/network/interfaces <<'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.50.1.3
    netmask 255.255.255.0
    gateway 10.50.1.1
EOF
ifdown eth0 2>/dev/null; ifup eth0
ip -br a
ip route
```

## 3.3 Arabasta

Masuk ke console `Arabasta`:

```bash
cat > /etc/network/interfaces <<'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.50.2.2
    netmask 255.255.255.0
    gateway 10.50.2.1
EOF
ifdown eth0 2>/dev/null; ifup eth0
ip -br a
ip route
```

## 3.4 Water7

`Water7` adalah server yang memakai `debinet`, dan perlu memasang `iptables`, `netcat`, serta `ifupdown`. Seperti pada `Firewall`, IP diberikan lebih dulu dengan perintah `ip` supaya `apt` bisa dipakai.

```bash
ip addr add 10.50.3.2/24 dev eth0; ip link set eth0 up; ip route add default via 10.50.3.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf
ip -br a
ip route
ping -c 3 8.8.8.8
```

Jika `ping 8.8.8.8` berhasil, NAT pada `Firewall` berjalan. Lanjutkan dengan instalasi package:

```bash
apt update && apt install -y ifupdown iptables netcat-traditional
```

Varian `netcat-traditional` dipilih agar penulisan perintah `nc` seragam dengan yang dipakai pada materi (`nc -l -p [PORT]`). Pastikan varian tersebut aktif:

```bash
nc -h 2>&1 | head -n 1
```

![Instalasi package Water7](img/05-install-water7.png)

Simpan konfigurasi interface:

```bash
cat > /etc/network/interfaces <<'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.50.3.2
    netmask 255.255.255.0
    gateway 10.50.3.1
EOF
```

Uji file tersebut:

```bash
ip addr flush dev eth0
mkdir -p /run/network; ifup eth0
ip -br a
ip route
```

Hasil yang diharapkan: `eth0` kembali memiliki alamat `10.50.3.2/24`, dan route default mengarah ke `10.50.3.1`.

> **Penting:** selesaikan instalasi package pada `Water7` **sebelum** mengerjakan bagian 10. Pada bagian itu `Water7` tidak lagi diizinkan keluar ke internet, sehingga `apt` tidak akan berfungsi.

---

# 4. Pengujian Awal

Sebelum firewall dipasang, pastikan seluruh jaringan berfungsi. Pengujian ini juga menjadi pembanding untuk hasil pada skenario berikutnya.

Dari `Baratie`:

```bash
ping -c 2 -W 2 10.50.1.1
ping -c 2 -W 2 10.50.1.3
ping -c 2 -W 2 10.50.2.2
ping -c 2 -W 2 10.50.3.2
ping -c 2 -W 2 8.8.8.8
```

Hasil yang diharapkan: seluruhnya berhasil. Hal yang sama berlaku untuk `Mariejois`, `Arabasta`, dan `Water7`.

Ringkasan hasil yang diharapkan:

| Dari | Ke | Hasil |
|---|---|---|
| `Baratie` | `Water7` (`10.50.3.2`) | Berhasil |
| `Mariejois` | `Arabasta` (`10.50.2.2`) | Berhasil |
| `Arabasta` | `Water7` (`10.50.3.2`) | Berhasil |
| `Water7` | `Baratie` (`10.50.1.2`) | Berhasil |
| `Baratie`, `Water7` | `8.8.8.8` | Berhasil (lewat NAT) |

![Pengujian awal](img/06-pengujian-awal.png)

Periksa kondisi iptables pada `Firewall`:

```bash
iptables -S
iptables -t nat -S
```

Hasil yang diharapkan:

```text
-P INPUT ACCEPT
-P FORWARD ACCEPT
-P OUTPUT ACCEPT
```

dan pada table `nat` hanya terdapat satu rule `MASQUERADE` pada `POSTROUTING`. Artinya, pada kondisi ini `Firewall` hanya meneruskan paket dan belum menyaring apa pun, sesuai penjelasan pada bagian 6.2 materi.

![iptables kondisi awal](img/07-iptables-awal.png)

---

# 5. Memahami INPUT, FORWARD, dan OUTPUT

Sebelum masuk ke skenario, bagian ini membuktikan satu hal yang sering membingungkan: **rule yang sama bisa berpengaruh atau tidak, bergantung pada chain tempat rule itu dipasang**. Seluruh rule pada bagian ini dipasang di `Firewall`, dan semuanya dihapus lagi di akhir.

## 5.1 Rule pada FORWARD

Pasang rule yang membuang ping (`echo-request`) pada chain `FORWARD`:

```bash
iptables -A FORWARD -p icmp --icmp-type echo-request -j DROP
```

Dari `Baratie`, uji dua tujuan:

```bash
ping -c 2 -W 2 10.50.1.1
ping -c 2 -W 2 10.50.3.2
```

Hasil yang diharapkan:

| Tujuan | Hasil | Alasan |
|---|---|---|
| `10.50.1.1` (router itu sendiri) | Berhasil | Paket ditujukan ke router, jalurnya `PREROUTING` -> `INPUT`. `FORWARD` tidak dilewati. |
| `10.50.3.2` (Water7) | Gagal | Paket hanya melewati router, jalurnya `PREROUTING` -> `FORWARD` -> `POSTROUTING`. |

Pada `Firewall`, lihat counter:

```bash
iptables -L FORWARD -n -v --line-numbers
```

Kolom `pkts` pada rule bernomor 1 bertambah sesuai jumlah ping yang dikirim. Hapus rule:

```bash
iptables -F FORWARD
```

![Demo FORWARD](img/08-demo-forward.png)

## 5.2 Rule pada INPUT

Pasang rule yang **sama** pada chain `INPUT`:

```bash
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
```

Ulangi dua ping dari `Baratie`:

```bash
ping -c 2 -W 2 10.50.1.1
ping -c 2 -W 2 10.50.3.2
```

Hasil yang diharapkan sekarang **terbalik**:

| Tujuan | Hasil | Alasan |
|---|---|---|
| `10.50.1.1` (router itu sendiri) | Gagal | Paket masuk ke chain `INPUT`. |
| `10.50.3.2` (Water7) | Berhasil | Paket hanya lewat, tidak pernah menyentuh `INPUT`. |

Hapus rule:

```bash
iptables -F INPUT
```

![Demo INPUT](img/09-demo-input.png)

## 5.3 Rule pada OUTPUT

Chain `OUTPUT` hanya berlaku untuk paket yang **dibuat oleh router sendiri**. Pasang rule yang membuang semua paket dari router menuju `Water7`:

```bash
iptables -A OUTPUT -d 10.50.3.2 -j DROP
```

Uji pada `Firewall`:

```bash
ping -c 2 -W 2 10.50.3.2
```

Uji juga dari `Baratie`:

```bash
ping -c 2 -W 2 10.50.3.2
```

Hasil yang diharapkan:

| Dari | Ke | Hasil | Alasan |
|---|---|---|---|
| `Firewall` | `Water7` | Gagal | Paket dibuat oleh router, melewati `OUTPUT`. |
| `Baratie` | `Water7` | Berhasil | Paket milik Baratie hanya diteruskan router, `OUTPUT` tidak dilewati. |

Hapus rule:

```bash
iptables -F OUTPUT
```

![Demo OUTPUT](img/10-demo-output.png)

## 5.4 Kesimpulan

| Chain | Berlaku untuk | Dipakai pada modul ini untuk |
|---|---|---|
| `INPUT` | Paket yang ditujukan ke mesin itu sendiri | Melindungi `Water7` (skenario 3) |
| `FORWARD` | Paket yang hanya melewati mesin | Mengatur lalu lintas antar-LAN di `Firewall` (skenario 1 dan 2) |
| `OUTPUT` | Paket yang dibuat oleh mesin itu sendiri | Tidak dipakai pada skenario, hanya demo |

Pastikan seluruh rule sudah bersih sebelum lanjut:

```bash
iptables -F
iptables -S
```

Hasil yang diharapkan: hanya tiga baris `-P ... ACCEPT`.

---

# 6. Skenario 1: Memblokir Baratie ke Water7

**Kebutuhan:** PC `Baratie` tidak diizinkan mengakses server `Water7`.

`Baratie` berada di LAN 1 dan `Water7` di LAN 3, sehingga lalu lintas di antara keduanya selalu melewati `Firewall`. Rule dipasang pada chain `FORWARD`.

## 6.1 Pasang Rule

Pada `Firewall`:

```bash
iptables -A FORWARD -s 10.50.1.2 -d 10.50.3.2 -j DROP
```

Arti rule: paket yang melewati router, berasal dari `10.50.1.2` (Baratie) dan menuju `10.50.3.2` (Water7), dibuang.

Periksa:

```bash
iptables -L FORWARD -n -v --line-numbers
```

![Rule skenario 1](img/11-skenario1-rule.png)

## 6.2 Uji

Dari `Baratie`:

```bash
ping -c 2 -W 2 10.50.3.2
```

Dari `Mariejois` dan `Arabasta`:

```bash
ping -c 2 -W 2 10.50.3.2
```

Hasil yang diharapkan:

| Dari | Ke | Hasil |
|---|---|---|
| `Baratie` | `Water7` | **Gagal** |
| `Mariejois` | `Water7` | Berhasil |
| `Arabasta` | `Water7` | Berhasil |
| `Baratie` | `Arabasta` | Berhasil |
| `Baratie` | `8.8.8.8` | Berhasil |

Hanya pasangan `Baratie` dan `Water7` yang terputus. Host lain tidak terpengaruh, begitu pula tujuan lain milik `Baratie`.

![Uji skenario 1](img/12-skenario1-uji.png)

## 6.3 Perhatikan Counter

Pada `Firewall`:

```bash
iptables -L FORWARD -n -v --line-numbers
```

Kolom `pkts` pada rule bernomor 1 sekarang tidak nol. Itu bukti bahwa rule ini yang menangani paket tadi.

## 6.4 Arah Sebaliknya

Dari `Water7`, uji ping ke `Baratie`:

```bash
ping -c 2 -W 2 10.50.1.2
```

Hasil yang diharapkan: **gagal juga**, meskipun rule hanya menyebut Baratie sebagai sumber. Permintaan dari `Water7` memang lolos, tetapi **balasan** dari `Baratie` ke `Water7` memiliki sumber `10.50.1.2` dan tujuan `10.50.3.2`, persis seperti yang dibuang rule tadi. Rule ini stateless, sehingga ia tidak membedakan permintaan dari balasan. Konsep ini dibahas pada bagian 10 materi.

## 6.5 Bersihkan Rule

```bash
iptables -D FORWARD -s 10.50.1.2 -d 10.50.3.2 -j DROP
```

---

# 7. Skenario 2: Memblokir Arabasta pada Jam Tertentu

**Kebutuhan:** PC `Arabasta` tidak dapat diakses pada pukul 07.00 sampai 17.00.

Rule ini memakai match `time`. Match tersebut membaca jam dalam **UTC**, sehingga jam WIB harus dikonversi (WIB = UTC + 7):

| Waktu (WIB) | Waktu (UTC) |
|---|---|
| 07.00 | 00:00 |
| 17.00 | 10:00 |

Jadi rentang yang dimaksud ditulis `--timestart 00:00 --timestop 10:00`.

## 7.1 Cek Jam pada Router

Pada `Firewall`:

```bash
date -u
```

Catat jam UTC yang tampil. Pada contoh di bawah, jam UTC saat ini diandaikan **06:56**. Sesuaikan dengan jam pada node kalian.

![Jam UTC](img/13-date-utc.png)

## 7.2 Bukti: Rentang yang Mencakup Jam Sekarang

Agar efek rule langsung terlihat, pakai rentang yang **mencakup** jam sekarang. Jika jam UTC saat ini 06:56, rentang `06:00` sampai `08:00` sudah cukup:

```bash
iptables -A FORWARD -d 10.50.2.2 -m time --timestart 06:00 --timestop 08:00 -j DROP
```

Sesuaikan `--timestart` dan `--timestop` dengan hasil `date -u` kalian.

Dari `Mariejois`:

```bash
ping -c 2 -W 2 10.50.2.2
```

Hasil yang diharapkan: **gagal**. Pada `Firewall`, `iptables -L FORWARD -n -v` menunjukkan counter rule bertambah, dan kolom keterangan menampilkan rentang waktu dengan akhiran `UTC`.

![Skenario 2 diblokir](img/14-skenario2-blokir.png)

## 7.3 Bukti: Rentang yang Tidak Mencakup Jam Sekarang

Hapus rule tadi, lalu pasang rule dengan rentang yang **tidak** mencakup jam sekarang. Dengan jam UTC 06:56, rentang `12:00` sampai `13:00` aman dipakai:

```bash
iptables -D FORWARD -d 10.50.2.2 -m time --timestart 06:00 --timestop 08:00 -j DROP
iptables -A FORWARD -d 10.50.2.2 -m time --timestart 12:00 --timestop 13:00 -j DROP
```

Ulangi ping dari `Mariejois`:

```bash
ping -c 2 -W 2 10.50.2.2
```

Hasil yang diharapkan: **berhasil**, karena jam sekarang berada di luar rentang.

![Skenario 2 diizinkan](img/15-skenario2-izin.png)

## 7.4 Rule Sesuai Kebutuhan

Setelah perilakunya terbukti, ganti dengan rule yang sesuai kebutuhan, yaitu 07.00 sampai 17.00 WIB:

```bash
iptables -D FORWARD -d 10.50.2.2 -m time --timestart 12:00 --timestop 13:00 -j DROP
iptables -A FORWARD -d 10.50.2.2 -m time --timestart 00:00 --timestop 10:00 -j DROP
```

Hasilnya bergantung pada kapan pengujian dilakukan:

| Waktu pengujian | Ping ke `Arabasta` |
|---|---|
| 07.00 sampai 17.00 WIB (00:00 sampai 10:00 UTC) | Gagal |
| Di luar rentang tersebut | Berhasil |

Periksa bentuk rule yang tersimpan:

```bash
iptables -S FORWARD
```

Pada sebagian versi iptables, baris rule ini ikut menampilkan `--datestop 2038-01-19T03:14:07`. Itu tampilan bawaan dan tidak perlu diubah.

## 7.5 Catatan

- Rule memakai `-d` (tujuan), sehingga yang tertutup adalah **akses menuju** `Arabasta`. Karena rule ini stateless, balasan untuk koneksi yang dimulai `Arabasta` sendiri (misalnya `Arabasta` ping `Water7`) juga bertujuan ke `Arabasta` dan ikut terbuang pada rentang tersebut. Silakan buktikan sendiri pada rentang yang mencakup jam sekarang.
- Rule `FORWARD` hanya mengatur paket yang **melewati** router. Akses dari `Firewall` itu sendiri ke `Arabasta` melewati chain `OUTPUT`, sehingga bila ingin ikut ditutup, diperlukan rule serupa pada `OUTPUT`.

## 7.6 Bersihkan Rule

```bash
iptables -F FORWARD
```

---

# 8. Skenario 3: Water7 Menolak HTTP

**Kebutuhan:** server `Water7` tidak diperbolehkan menerima koneksi HTTP.

HTTP memakai TCP port 80. Berbeda dengan dua skenario sebelumnya, rule ini dipasang **pada `Water7` sendiri**, di chain `INPUT`, karena yang ingin dibatasi adalah apa yang diterima server itu. Cara ini disebut *host-based firewall* dan melindungi `Water7` dari **semua** sumber, termasuk host yang berada di LAN yang sama dengannya.

> Rule yang setara bisa juga dipasang di `Firewall` dengan `iptables -A FORWARD -d 10.50.3.2 -p tcp --dport 80 -j DROP`. Bedanya, rule itu hanya melindungi dari lalu lintas yang melewati router.

Pengujian memakai `nc`, dengan port 80 sebagai port yang ditutup dan port 8080 sebagai pembanding yang tetap terbuka.

## 8.1 Siapkan Listener dan Uji Sebelum Rule

Pada `Water7`, buka dua listener di latar belakang. Keluaran masing-masing ditulis ke file:

```bash
nc -l -p 80 > /tmp/p80.txt &
nc -l -p 8080 > /tmp/p8080.txt &
```

Dari `Mariejois`, kirim satu pesan ke setiap port:

```bash
echo "halo-80" | nc -w 3 10.50.3.2 80; echo "exit=$?"
echo "halo-8080" | nc -w 3 10.50.3.2 8080; echo "exit=$?"
```

Pada `Water7`, periksa isi file:

```bash
cat /tmp/p80.txt
cat /tmp/p8080.txt
```

Hasil yang diharapkan: `p80.txt` berisi `halo-80` dan `p8080.txt` berisi `halo-8080`. Kedua port masih terbuka. Listener berhenti sendiri setelah satu koneksi selesai.

![Listener sebelum rule](img/16-skenario3-sebelum.png)

## 8.2 Pasang Rule DROP

Pada `Water7`:

```bash
iptables -A INPUT -p tcp --dport 80 -j DROP
```

Nyalakan ulang listener (listener lama sudah berhenti), dan kosongkan file:

```bash
pkill nc
nc -l -p 80 > /tmp/p80.txt &
nc -l -p 8080 > /tmp/p8080.txt &
```

Dari `Mariejois`:

```bash
echo "halo-80" | nc -w 3 10.50.3.2 80; echo "exit=$?"
echo "halo-8080" | nc -w 3 10.50.3.2 8080; echo "exit=$?"
```

Hasil yang diharapkan:

| Port | Perilaku | Isi file pada Water7 |
|---|---|---|
| 80 | Perintah **menggantung sekitar 3 detik** (sesuai `-w 3`), lalu selesai dengan `exit` bukan 0 | Kosong |
| 8080 | Berhasil, `exit=0` | Berisi `halo-8080` |

Port 80 tidak pernah menjawab, dan pengirim menunggu sampai timeout. Itulah ciri khas `DROP`.

![Skenario 3 DROP](img/17-skenario3-drop.png)

Lihat counter pada `Water7`:

```bash
iptables -L INPUT -n -v --line-numbers
```

Kolom `pkts` pada rule `DROP` bertambah. Jumlahnya bisa lebih dari satu karena klien mengirim ulang paket `SYN` selama menunggu jawaban.

## 8.3 Ganti dengan REJECT

Ganti `DROP` dengan `REJECT` untuk membandingkannya:

```bash
iptables -D INPUT -p tcp --dport 80 -j DROP
iptables -A INPUT -p tcp --dport 80 -j REJECT --reject-with tcp-reset
```

Nyalakan ulang listener port 80:

```bash
pkill nc
nc -l -p 80 > /tmp/p80.txt &
```

Uji lagi dari `Mariejois`:

```bash
echo "halo-80" | nc -w 3 10.50.3.2 80; echo "exit=$?"
```

Hasil yang diharapkan: perintah **langsung selesai** dengan pesan penolakan (`Connection refused` atau sejenisnya) dan `exit` bukan 0, tanpa menunggu 3 detik.

![Skenario 3 REJECT](img/18-skenario3-reject.png)

| | `DROP` | `REJECT` |
|---|---|---|
| Waktu sampai gagal | Sekitar 3 detik (timeout) | Hampir seketika |
| Yang dikirim server | Tidak ada | Paket `RST` |

## 8.4 Mengamati dengan tcpdump (Opsional)

Untuk melihat perbedaannya pada level paket, pasang `tcpdump` di `Water7`:

```bash
apt install -y tcpdump
```

Jalankan di latar belakang, lalu uji dari `Mariejois`:

```bash
tcpdump -i eth0 -n -l tcp port 80 > /tmp/dump80.txt 2>&1 &
```

Setelah pengujian selesai:

```bash
pkill tcpdump
cat /tmp/dump80.txt
```

Hasil yang diharapkan: pada kondisi `DROP`, hanya terlihat paket `SYN` yang datang (beberapa kali, karena dikirim ulang) tanpa jawaban. Pada kondisi `REJECT`, terlihat `SYN` yang segera dijawab paket `RST`. `tcpdump` menangkap paket sebelum diproses firewall, sehingga paket yang akhirnya dibuang pun tetap terlihat masuk.

![tcpdump DROP dan REJECT](img/19-skenario3-tcpdump.png)

## 8.5 Bersihkan

```bash
iptables -F INPUT
pkill nc
```

---

# 9. Skenario 4: Mengalihkan Baratie ke Mariejois dengan DNAT

**Kebutuhan:** semua paket yang menuju PC `Baratie` diarahkan ke PC `Mariejois`.

Pengalihan alamat tujuan dilakukan dengan **DNAT** pada chain `PREROUTING` di `Firewall`. Penguji berada di `Water7` (LAN 3), sehingga paketnya pasti melewati router. `Baratie` dan `Mariejois` berada pada LAN yang sama, tetapi itu tidak mengganggu karena penguji berada di luar LAN tersebut.

## 9.1 Siapkan Listener dan Uji Sebelum DNAT

Pada `Baratie`:

```bash
nc -l -p 9000 > /tmp/baratie.txt &
```

Pada `Mariejois`:

```bash
nc -l -p 9000 > /tmp/mariejois.txt &
```

Dari `Water7`, kirim pesan ke alamat `Baratie`:

```bash
echo "sebelum-dnat" | nc -w 3 10.50.1.2 9000; echo "exit=$?"
```

Periksa pada `Baratie` dan `Mariejois`:

```bash
cat /tmp/baratie.txt
cat /tmp/mariejois.txt
```

Hasil yang diharapkan: `baratie.txt` berisi `sebelum-dnat`, sedangkan `mariejois.txt` kosong. Pesan sampai ke tujuan yang benar.

![Sebelum DNAT](img/20-skenario4-sebelum.png)

## 9.2 Pasang Rule DNAT

Nyalakan ulang listener pada `Baratie` dan `Mariejois` (listener lama sudah berhenti):

```bash
pkill nc
nc -l -p 9000 > /tmp/baratie.txt &
```

```bash
pkill nc
nc -l -p 9000 > /tmp/mariejois.txt &
```

Pada `Firewall`, pasang rule:

```bash
iptables -t nat -A PREROUTING -d 10.50.1.2 -j DNAT --to-destination 10.50.1.3
```

Arti rule: paket yang masuk ke router dengan tujuan `10.50.1.2` (Baratie) diubah tujuannya menjadi `10.50.1.3` (Mariejois) sebelum keputusan routing.

Periksa table `nat`:

```bash
iptables -t nat -L PREROUTING -n -v --line-numbers
```

![Rule DNAT](img/21-skenario4-rule.png)

## 9.3 Uji Setelah DNAT

Dari `Water7`, kirim pesan ke **alamat yang sama** seperti tadi, yaitu alamat `Baratie`:

```bash
echo "sesudah-dnat" | nc -w 3 10.50.1.2 9000; echo "exit=$?"
```

Periksa pada `Baratie` dan `Mariejois`:

```bash
cat /tmp/baratie.txt
cat /tmp/mariejois.txt
```

Hasil yang diharapkan: kali ini `mariejois.txt` berisi `sesudah-dnat`, sedangkan `baratie.txt` **kosong**. Pengirim tetap mengetik alamat `Baratie`, tetapi paketnya tiba di `Mariejois`.

![Sesudah DNAT](img/22-skenario4-sesudah.png)

## 9.4 Buktikan dengan tcpdump dan conntrack

Pada `Mariejois`, tangkap ICMP di latar belakang:

```bash
tcpdump -i eth0 -n -l icmp > /tmp/icmp.txt 2>&1 &
```

Dari `Water7`, ping alamat `Baratie`:

```bash
ping -c 2 -W 2 10.50.1.2
```

Perhatikan bahwa balasannya **tetap tampak datang dari `10.50.1.2`**, sehingga penguji tidak bisa membedakan dari ping saja. Firewall menerjemahkan alamat sumber balasan kembali ke alamat yang diharapkan pengirim.

Pada `Mariejois`:

```bash
pkill tcpdump
cat /tmp/icmp.txt
```

Hasil yang diharapkan: terlihat paket `echo request` dari `10.50.3.2` menuju `10.50.1.3` (alamat Mariejois, bukan Baratie), dan `echo reply` kembali dari `10.50.1.3`. Berarti paket benar-benar sampai ke `Mariejois`.

Pada `Firewall`, lihat catatan terjemahan alamat:

```bash
conntrack -L 2>/dev/null | grep 9000
```

Hasilnya berupa satu baris dengan dua kelompok alamat. Contoh bentuknya:

```text
tcp  6 117 TIME_WAIT src=10.50.3.2 dst=10.50.1.2 sport=52922 dport=9000 src=10.50.1.3 dst=10.50.3.2 sport=9000 dport=52922 [ASSURED]
```

Kelompok pertama adalah arah permintaan (`dst=10.50.1.2`, alamat Baratie yang diketik penguji). Kelompok kedua adalah arah balasan (`src=10.50.1.3`, alamat Mariejois yang sebenarnya membalas). Selisih antara kedua kelompok itulah hasil DNAT.

![Bukti DNAT](img/23-skenario4-bukti.png)

## 9.5 Catatan

- IP forwarding harus aktif. Tanpanya paket yang sudah dialihkan tidak akan diteruskan oleh router.
- Rule DNAT hanya menyentuh paket pertama dari setiap koneksi. Paket-paket berikutnya dan balasannya diterjemahkan otomatis oleh connection tracking.
- Jika `FORWARD` berpolicy `DROP`, rule yang mengizinkan harus menyebut tujuan **setelah** DNAT, yaitu `10.50.1.3`, bukan `10.50.1.2`.

## 9.6 Bersihkan

Pada `Firewall`:

```bash
iptables -t nat -D PREROUTING -d 10.50.1.2 -j DNAT --to-destination 10.50.1.3
```

Pada `Baratie` dan `Mariejois`:

```bash
pkill nc
```

---

# 10. Default Deny dan Stateful Filtering

Pada skenario sebelumnya, semua chain memakai policy `ACCEPT` dan rule hanya menyebutkan apa yang **dilarang**. Bagian ini membalik arahnya: semua lalu lintas antar-LAN dilarang, dan hanya yang disebut yang diizinkan. Konsepnya ada pada bagian 4.4 dan 10 materi.

> **Peringatan:** setelah bagian ini, `Water7` tidak lagi diizinkan keluar ke internet. Pastikan semua `apt install` pada `Water7` sudah selesai (bagian 3.4 dan 8.4).

Pada `Firewall`, bersihkan rule sebelumnya tanpa menyentuh `MASQUERADE`:

```bash
iptables -F
iptables -t nat -F PREROUTING
iptables -S
```

## 10.1 Policy DROP Tanpa Rule Balasan

Ubah policy `FORWARD` menjadi `DROP`, lalu izinkan hanya paket dari LAN 1 (`eth1`) menuju internet (`eth0`):

```bash
iptables -P FORWARD DROP
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
```

Dari `Baratie`:

```bash
ping -c 2 -W 2 8.8.8.8
```

Hasil yang diharapkan: **gagal**, padahal arah `eth1` ke `eth0` sudah diizinkan. Permintaan ping memang keluar, tetapi balasan dari internet masuk lewat `eth0` dan hendak keluar lewat `eth1`, arah yang tidak diizinkan oleh rule mana pun. Paket itu jatuh ke default policy dan dibuang.

Lihat counter:

```bash
iptables -L FORWARD -n -v --line-numbers
```

Baris pertama judul chain menampilkan `policy DROP` beserta jumlah paket yang dibuang karena tidak cocok dengan rule mana pun. Angka itu bertambah setiap ping.

![Policy DROP tanpa balasan](img/24-policy-drop-gagal.png)

## 10.2 Tambahkan Rule Stateful

Sisipkan rule yang mengizinkan paket dari koneksi yang sudah ada **di posisi paling atas**:

```bash
iptables -I FORWARD 1 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

Ulangi uji dari `Baratie`:

```bash
ping -c 2 -W 2 8.8.8.8
```

Hasil yang diharapkan: **berhasil**. Balasan sekarang dikenali sebagai bagian dari koneksi yang dimulai `Baratie`, sehingga lolos lewat rule baru.

Lanjutkan dengan pengujian dari host lain:

```bash
ping -c 2 -W 2 8.8.8.8
ping -c 2 -W 2 10.50.3.2
```

Jalankan kedua perintah itu dari `Mariejois`, lalu jalankan `ping -c 2 -W 2 8.8.8.8` dari `Water7`. Bandingkan dengan tabel:

| Dari | Ke | Hasil | Alasan |
|---|---|---|---|
| `Baratie` | `8.8.8.8` | Berhasil | LAN 1 ke internet diizinkan, balasannya `ESTABLISHED` |
| `Mariejois` | `8.8.8.8` | Berhasil | Sama seperti Baratie |
| `Water7` | `8.8.8.8` | Gagal | `eth3` ke `eth0` tidak diizinkan oleh rule mana pun |
| `Mariejois` | `Water7` | Gagal | LAN 1 ke LAN 3 belum diizinkan, jatuh ke policy `DROP` |

Hal yang berubah dari 10.1 hanya satu rule. Perhatikan bahwa koneksi yang dimulai dari internet menuju LAN tetap tertolak, karena paket pertamanya berstatus `NEW` dan tidak ada rule yang mengizinkannya.

![Rule stateful](img/25-stateful-berhasil.png)

## 10.3 Izinkan Satu Layanan Tertentu

Izinkan LAN 1 mengakses TCP port 8080 pada `Water7`, dan tidak yang lain:

```bash
iptables -A FORWARD -i eth1 -o eth3 -p tcp --dport 8080 -j ACCEPT
```

Pada `Water7`, buka listener:

```bash
nc -l -p 8080 > /tmp/p8080.txt &
```

Dari `Mariejois`:

```bash
echo "tes-8080" | nc -w 3 10.50.3.2 8080; echo "exit=$?"
ping -c 2 -W 2 10.50.3.2
```

Hasil yang diharapkan: pengiriman ke port 8080 **berhasil** (`p8080.txt` pada `Water7` berisi `tes-8080`), sedangkan `ping` ke `Water7` tetap **gagal**. Hanya TCP port 8080 dari LAN 1 yang diizinkan. Balasannya lolos karena rule `ESTABLISHED` di baris paling atas.

Tampilkan rule akhir:

```bash
iptables -L FORWARD -n -v --line-numbers
```

Susunan yang diharapkan:

```text
Chain FORWARD (policy DROP ...)
num   pkts bytes target     prot opt in     out     source       destination
1        .     . ACCEPT     0    --  *      *       0.0.0.0/0    0.0.0.0/0     ctstate RELATED,ESTABLISHED
2        .     . ACCEPT     0    --  eth1   eth0    0.0.0.0/0    0.0.0.0/0
3        .     . ACCEPT     6    --  eth1   eth3    0.0.0.0/0    0.0.0.0/0     tcp dpt:8080
```

![Default deny lengkap](img/26-default-deny.png)

## 10.4 Kembalikan ke Kondisi Awal

```bash
iptables -P FORWARD ACCEPT
iptables -F
pkill nc
```

Policy dikembalikan **sebelum** rule dihapus, agar tidak ada saat di mana semua lalu lintas terblokir.