# Modul 1: Wireshark & Setup GNS3

## Daftar Isi
- [0. Pendahuluan](#0-pendahuluan)
- [1. Wireshark](#1-wireshark)
  - [1.1 Struktur Paket Jaringan](#11-struktur-paket-jaringan)
  - [1.2 Instalasi](#12-instalasi)
  - [1.3 Filter](#13-filter)
    - [1.3.1 Capture Filter](#131-capture-filter)
    - [1.3.2 Display Filter](#132-display-filter)
    - [1.3.3 Perbandingan Capture Filter vs Display Filter](#133-perbandingan-capture-filter-vs-display-filter)
  - [1.4 Navigasi UI dan Ringkasan Trafik (Statistics)](#14-navigasi-ui-dan-ringkasan-trafik-statistics)
    - [1.4.1 Panel Utama dan Pewarnaan Paket](#141-panel-utama-dan-pewarnaan-paket)
    - [1.4.2 Follow Stream (TCP, UDP, HTTP)](#142-follow-stream-tcp-udp-http)
    - [1.4.3 Ringkasan Trafik (Statistics)](#143-ringkasan-trafik-statistics)
  - [1.5 Export Data Hasil Packet Capture](#15-export-data-hasil-packet-capture)
  - [1.6 Menangkap dan Mendekripsi Trafik HTTPS/TLS](#16-menangkap-dan-mendekripsi-trafik-httpstls)
  - [1.7 Studi Kasus: Memantau Trafik FTP](#17-studi-kasus-memantau-trafik-ftp)
    - [1.7.1 Arsitektur Dual-Channel FTP: Active vs Passive Mode](#171-arsitektur-dual-channel-ftp-active-vs-passive-mode)
    - [1.7.2 Menyiapkan Server (FileZilla Server)](#172-menyiapkan-server-filezilla-server)
    - [1.7.3 Koneksi dari Client](#173-koneksi-dari-client)
    - [1.7.4 Upload dan Download](#174-upload-dan-download)
  - [1.8 Pola Protokol Jaringan Esensial](#18-pola-protokol-jaringan-esensial)
    - [1.8.1 TCP Three-Way Handshake dan Teardown](#181-tcp-three-way-handshake-dan-teardown)
    - [1.8.2 Resolusi Alamat dengan ARP](#182-resolusi-alamat-dengan-arp)
    - [1.8.3 Mekanisme Diagnostik ICMP](#183-mekanisme-diagnostik-icmp)
- [2. GNS3](#2-gns3)
  - [2.1 Apa itu GNS3?](#21-apa-itu-gns3)
  - [2.2 Instalasi GNS3 VM](#22-instalasi-gns3-vm)
    - [Opsi A: VirtualBox](#opsi-a-virtualbox)
    - [Opsi B: VMware Workstation Pro](#opsi-b-vmware-workstation-pro)
    - [Troubleshooting Virtualisasi Hardware (VT-x, AMD-V, Hyper-V)](#troubleshooting-virtualisasi-hardware-vt-x-amd-v-hyper-v)
  - [2.3 Memasukkan Image Node ke GNS3](#23-memasukkan-image-node-ke-gns3)
  - [2.4 Instalasi dan Setup GNS3 Client](#24-instalasi-dan-setup-gns3-client)
  - [2.5 Setup IP di Node](#25-setup-ip-di-node)
  - [2.6 Akses Sebuah Node ke Internet](#26-akses-sebuah-node-ke-internet)
  - [2.7 Membuat Topologi Terintegrasi](#27-membuat-topologi-terintegrasi)
    - [2.7.1 Skema Pengalamatan IP](#271-skema-pengalamatan-ip)
    - [2.7.2 Konfigurasi Router Linux (Multi-Homed)](#272-konfigurasi-router-linux-multi-homed)
    - [2.7.3 Mengaktifkan Kernel IP Forwarding](#273-mengaktifkan-kernel-ip-forwarding)
    - [2.7.4 Konfigurasi Source NAT (iptables MASQUERADE)](#274-konfigurasi-source-nat-iptables-masquerade)
    - [2.7.5 Konfigurasi Client dan DNS Resolver](#275-konfigurasi-client-dan-dns-resolver)
    - [2.7.6 Verifikasi Konektivitas End-to-End](#276-verifikasi-konektivitas-end-to-end)
  - [2.8 Ketentuan, Persistensi, Tips, Trik, dan Troubleshooting](#28-ketentuan-persistensi-tips-trik-dan-troubleshooting)
- [3. Menghubungkan Wireshark dengan GNS3](#3-menghubungkan-wireshark-dengan-gns3)
  - [3.1 Capture Langsung dari Link Topologi](#31-capture-langsung-dari-link-topologi)
  - [3.2 Capture di Dalam Node dengan tcpdump dan TShark](#32-capture-di-dalam-node-dengan-tcpdump-dan-tshark)
  - [3.3 Contoh Skenario Analisis: Verifikasi SNAT dan ARP](#33-contoh-skenario-analisis-verifikasi-snat-dan-arp)
- [4. Latihan](#4-latihan)
- [5. Troubleshooting Common Pitfalls](#5-troubleshooting-common-pitfalls)
- [6. Referensi](#6-referensi)

---

## 0. Pendahuluan

GNS3 dan Wireshark adalah dua alat yang saling melengkapi dalam rekayasa jaringan komputer. **GNS3** mensimulasikan topologi jaringan (router, switch, host) tanpa memerlukan perangkat fisik, sedangkan **Wireshark** menangkap dan membedah paket yang melintas di jaringan tersebut. Modul ini membahas instalasi dan konfigurasi keduanya, serta integrasi keduanya untuk menganalisis protokol secara langsung pada topologi simulasi.

> **Catatan versi:** Perangkat lunak di modul ini (Wireshark, GNS3, VirtualBox, VMware Workstation, FileZilla) dirilis secara berkala. Gunakan selalu versi stabil terbaru dari situs resmi masing-masing, bukan dari tautan usang yang tidak lagi didukung.

---

## 1. Wireshark

Wireshark adalah aplikasi penganalisa paket jaringan (*network packet analyzer*). Aplikasi ini menangkap paket yang lewat di sebuah interface jaringan dalam mode promiscuous dan menampilkan isinya secara mendalam, mulai dari layer fisik hingga data aplikasi.

### 1.1 Struktur Paket Jaringan

Sebuah paket jaringan terbentuk melalui proses enkapsulasi berlapis:

**1. Header**: Berisi alamat dan data kontrol lain yang dibawa paket:

| Field Header | Fungsi / Keterangan |
| :--- | :--- |
| Panjang paket | Beberapa jaringan memiliki panjang paket baku (*fixed-length*), yang lain bergantung pada header untuk menyimpan informasi panjang |
| Sinkronisasi | Bit yang membantu paket mencocokkan jaringan yang dituju |
| Nomor paket | Menunjukkan urutan dari total paket yang ada (Sequence Number) |
| Protokol | Menunjukkan jenis data yang dibawa (HTTP, FTP, DNS, TCP, UDP, ICMP) |
| Alamat tujuan | Ke mana paket dikirim (Destination MAC pada Layer 2, Destination IP pada Layer 3, Destination Port pada Layer 4) |
| Alamat asal | Dari mana paket dikirim (Source MAC pada Layer 2, Source IP pada Layer 3, Source Port pada Layer 4) |

**2. Payload**: Disebut juga *body* dari paket, berisi muatan data sebenarnya yang ditransmisikan oleh aplikasi pengguna.

**3. Trailer**: Kadang disebut *footer*, biasanya berisi bit penanda akhir frame dan bit pengecekan kesalahan transmisi (*Frame Check Sequence* / FCS berbasis CRC32).

---

### 1.2 Instalasi

**Windows**
Unduh installer resmi dari [wireshark.org/download.html](https://www.wireshark.org/download.html). Installer Windows sudah menyertakan **Npcap** sebagai driver capture pengganti WinPcap yang sudah usang. Pastikan mencentang opsi instalasi Npcap dalam mode kompatibel WinPcap API.

**Linux (Debian / Ubuntu / Kali)**
Install lewat package manager:
```bash
sudo apt update
sudo apt install -y wireshark tshark
```
Saat instalasi muncul pertanyaan apakah user non-root boleh melakukan capture, pilih **Yes**. Kemudian tambahkan user kalian ke group `wireshark`:
```bash
sudo usermod -aG wireshark $USER
```
Terapkan perubahan group dengan `newgrp wireshark` atau lakukan logout/login ulang agar Wireshark dapat berjalan tanpa perintah `sudo`.

Jalankan Wireshark dan pilih interface yang ingin diamati. Tampilan awalnya sebagai berikut:

![wireshark](images/wireshark-awal.png)

**TShark**
Satu paket instalasi Wireshark juga menyertakan **TShark**, yaitu versi command-line dari Wireshark. TShark berguna untuk capture di lingkungan server tanpa GUI atau langsung di dalam container node GNS3. Pembahasan lebih mendalam ada pada [bagian 3.2](#32-capture-di-dalam-node-dengan-tcpdump-dan-tshark).

---

### 1.3 Filter

Wireshark memiliki 2 jenis filter dengan arsitektur berbeda: **Capture Filter** dan **Display Filter**.

#### 1.3.1 Capture Filter

![Capture](images/capture-filter-menu.png)

- **Definisi**: Menyaring paket pada tingkat driver/kernel sebelum disimpan ke memori buffer. Paket yang tidak memenuhi kriteria filter dibuang seketika dan tidak dapat dikembalikan.
- Sintaks filter menggunakan format **Berkeley Packet Filter (BPF)** yang terdiri dari satu atau lebih primitive:
  `[type] [dir] [proto] [id]`

| Qualifier | Keterangan | Contoh |
| :--- | :--- | :--- |
| type | Jenis id/nama yang menjadi target filter | host, net, port, portrange |
| dir | Arah paket dari/ke id | src, dst, src or dst |
| proto | Protokol target | ether, ip, ip6, arp, tcp, udp, icmp |

Sintaks dapat digabungkan dengan negasi (`!` atau `not`), konjungsi (`&&` atau `and`), dan disjungsi (`||` atau `or`).

| Filter expression | Keterangan |
| :--- | :--- |
| `host 10.151.36.1` | Menangkap semua paket dari/ke alamat 10.151.36.1 |
| `src host 10.151.36.1` | Menangkap semua paket yang berasal dari 10.151.36.1 |
| `net 192.168.0.0/24` | Menangkap semua paket dari/ke subnet 192.168.0.0/24 |
| `udp port 80` | Menangkap paket UDP dari/ke port 80 |
| `tcp src port 22 or host 10.151.36.30` | Paket TCP dari port 22, atau paket apa pun dari/ke 10.151.36.30 |
| `not arp and not icmp` | Mengabaikan seluruh lalu lintas ARP dan ICMP |

Contoh hasil capture filter `host 10.151.36.1`:

![Contoh-capture](images/capture-filter-contoh.png)

#### 1.3.2 Display Filter

![Display](images/display-filter-menu.png)

- **Definisi**: Memilah paket yang **ditampilkan** pada layar dari kumpulan paket yang sudah tersimpan di buffer memori. Filter ini tidak membuang data.
- Sintaks umum: `[protokol].[field] [comparison operator] [value]`

| Operator Teks | Simbol | Arti |
| :--- | :--- | :--- |
| eq | == | Sama dengan |
| ne | != | Tidak sama dengan |
| gt | > | Lebih besar dari |
| lt | < | Lebih kecil dari |
| ge | >= | Lebih besar atau sama dengan |
| le | <= | Lebih kecil atau sama dengan |
| contains | | Mengandung teks tertentu |
| matches | ~ | Cocok dengan regular expression |
| bitwise_and | & | Operasi logika bit |

Beberapa filter dapat digabungkan menggunakan operator logika: `and` (`&&`), `or` (`||`), `xor` (`^^`), `not` (`!`).

| Filter expression | Keterangan |
| :--- | :--- |
| `tcp.port == 443` | Semua paket TCP dari/ke port 443 |
| `ip.src == 192.168.0.1 or ip.dst == 192.168.0.1` | Paket dari atau ke 192.168.0.1 |
| `http.request.uri contains "login"` | Paket HTTP yang URI tujuannya memuat kata "login" |
| `quic` | Paket QUIC (protokol transport HTTP/3) |
| `tcp.flags.syn == 1 && tcp.flags.ack == 0` | Inisiasi awal koneksi TCP (paket SYN) |

Contoh hasil display filter `tcp.port == 80`:

![Contoh-display](images/display-filter-contoh.png)

#### 1.3.3 Perbandingan Capture Filter vs Display Filter

| Parameter | Capture Filter | Display Filter |
| :--- | :--- | :--- |
| **Lokasi Eksekusi** | Kernel / Driver Npcap / libpcap | Userspace Wireshark Engine |
| **Dampak Paket Gagal** | Dibuang permanen dari memori | Tetap tersimpan di buffer, hanya disembunyikan |
| **Standar Sintaks** | Berkeley Packet Filter (BPF) | Wireshark Protocol Field Notation |
| **Contoh IP Filter** | `host 192.168.1.1` | `ip.addr == 192.168.1.1` |
| **Contoh Port Filter** | `tcp port 80` | `tcp.port == 80` |

---

### 1.4 Navigasi UI dan Ringkasan Trafik (Statistics)

#### 1.4.1 Panel Utama dan Pewarnaan Paket
Antarmuka Wireshark dibagi menjadi 3 panel:
1. **Packet List Pane**: Menampilkan ringkasan nomor frame, waktu relatif, IP asal, IP tujuan, protokol, panjang frame, dan info ringkas.
2. **Packet Details Pane**: Struktur hierarki dekonstruksi layer (Frame, Ethernet, IPv4, TCP/UDP, Application Data).
3. **Packet Bytes Pane**: Representasi heksadesimal mentah di sisi kiri dan representasi ASCII di sisi kanan.

Skema warna default:
- Hijau: Paket protokol HTTP web.
- Biru muda: Lalu lintas DNS.
- Ungu muda: Paket data TCP biasa.
- Hitam dengan teks merah: Masalah transmisi TCP (Retransmission, Duplicate ACK, ZeroWindow, Reset RST).

#### 1.4.2 Follow Stream (TCP, UDP, HTTP)
Fitur ini merekonstruksi seluruh aliran data dua arah antara client dan server:
1. Klik kanan pada paket TCP/HTTP yang ingin dianalisis.
2. Pilih **Follow -> TCP Stream** (atau HTTP Stream).
3. Jendela dialog menampilkan data utuh: teks berwarna merah berasal dari Client ke Server, dan teks berwarna biru adalah respons dari Server ke Client.

#### 1.4.3 Ringkasan Trafik (Statistics)

Menu **Statistics** menyajikan gambaran agregat saat capture berisi ribuan paket:

- **Statistics -> Protocol Hierarchy**: Menampilkan persentase distribusi paket dan byte untuk setiap protokol. Membantu melihat protokol apa yang paling mendominasi jaringan.

- **Statistics -> Conversations**: Menampilkan matriks komunikasi antar-dua perangkat beserta total volume data yang saling dipertukarkan. Berguna melacak perangkat yang paling banyak menyerap bandwidth.

- **Statistics -> I/O Graphs**: Grafik kurva volume trafik terhadap waktu untuk mengamati lonjakan trafik.

---

### 1.5 Export Data Hasil Packet Capture

1. Setelah paket tertangkap, pilih menu **File -> Export Objects -> (protokol yang diinginkan)**. Contoh: HTTP.

   ![export](images/export-objects-menu.png)

2. Pilih objek file yang ingin diekspor (misal gambar atau dokumen dari situs web), klik **Save**, lalu tentukan folder penyimpanan di komputer host.

   ![Pilih-paket](images/export-pilih-objek.png)

3. File hasil rekonstruksi berhasil disimpan ke penyimpanan lokal.

---

### 1.6 Menangkap dan Mendekripsi Trafik HTTPS/TLS

Situs web modern menggunakan enkripsi **HTTPS/TLS** (port 443). Wireshark dapat menangkap paketnya, namun isi muatan payload hanya terlihat sebagai `Application Data` terenkripsi. Untuk kebutuhan praktikum analitik, kita dapat mendekripsi trafik HTTPS milik sendiri menggunakan mekanisme environment variable `SSLKEYLOGFILE`.

Langkah-langkah:

1. Tentukan lokasi penyimpanan file log kunci enkripsi sebelum membuka browser:
   - Windows (Command Prompt):
     ```cmd
     set SSLKEYLOGFILE=C:\Users\Public\tls-keys.log
     ```
   - Windows (PowerShell):
     ```powershell
     $env:SSLKEYLOGFILE="C:\Users\Public\tls-keys.log"
     ```
   - Linux / macOS:
     ```bash
     export SSLKEYLOGFILE=~/tls-keys.log
     ```
2. Dari sesi terminal yang sama, buka browser:
   - Windows: jalankan Google Chrome atau Firefox.
   - Linux: ketik `google-chrome &` atau `firefox &`.
3. Mulai capture di Wireshark pada interface aktif, lalu akses situs HTTPS (misalnya `https://example.com`).
4. Di Wireshark, buka **Edit -> Preferences -> Protocols -> TLS**. Pada kolom **(Pre)-Master-Secret log filename**, isi path ke file log kunci yang ditentukan tadi.

5. Terapkan display filter `http || http2` atau `tls`. Paket yang semula bertuliskan `Application Data` kini terbuka isinya dan menampilkan request HTTP/1.1 atau HTTP/2 secara plaintext.

> **Catatan keamanan:** File key log ini berisi kunci simetris sesi. Jangan pernah membagikan file ini ke orang lain dan hapus file setelah sesi praktikum selesai.

---

### 1.7 Studi Kasus: Memantau Trafik FTP

Protokol File Transfer Protocol (FTP) sangat cocok untuk studi analisis protokol karena seluruh autentikasi dan kontrol ditransmisikan dalam bentuk plaintext tanpa enkripsi.

Sebelum menghubungkan client ke server FTP, pastikan Wireshark sudah menyala dan aktif menangkap interface yang relevan.

#### 1.7.1 Arsitektur Dual-Channel FTP: Active vs Passive Mode
FTP menggunakan dua koneksi terpisah:
1. **Control Connection (Port 21)**: Dipakai untuk pertukaran perintah teks (`USER`, `PASS`, `PORT`, `PASV`, `LIST`, `QUIT`).
2. **Data Connection**: Saluran terpisah untuk mengalirkan file mentah dan daftar direktori:
   - **Active Mode**: Server menginisiasi koneksi dari port 20 ke port acak client yang ditentukan lewat instruksi `PORT`.
   - **Passive Mode (PASV)**: Client menginisiasi koneksi dari port acak dirinya ke port acak server yang ditentukan lewat instruksi `PASV`.

#### 1.7.2 Menyiapkan Server (FileZilla Server)

FileZilla Server modern menggunakan arsitektur service di background dengan antarmuka administrasi terpisah.

1. Install FileZilla Server dari [filezilla-project.org](https://filezilla-project.org/download.php?type=server). Tentukan port admin dan password administrator saat instalasi.
2. Buka **FileZilla Server Administration Interface**, masukkan alamat host `127.0.0.1` beserta password admin untuk terhubung ke service.

   ![FZ Admin Connect](images/fz-admin-connect.png)

3. Buka **Server -> Configure** (atau shortcut `Ctrl+F`), masuk ke bagian **Users**. Klik **Add**, beri nama user (misal `jarkom2026`), pilih opsi **Require a password to log in**, dan tentukan passwordnya.

   ![FZ Add User](images/fz-add-user.png)

4. Pada user yang sama, atur **Mount Points**:
   - *Virtual path*: `/`
   - *Native path*: Folder di komputer kalian (misal `C:\ftp_share` atau `/srv/ftp`).
   - Berikan izin *Read* dan *Write*.

   ![FZ Mount Point](images/fz-mount-point.png)

5. Klik **OK** untuk menerapkan konfigurasi.

#### 1.7.3 Koneksi dari Client

**Koneksi via FileZilla Client**
Buka FileZilla Client, isi kolom *Host*, *Username*, *Password*, dan *Port 21*, lalu klik tombol **Quickconnect**.

![Login FileZilla](images/fz-client-connect.png)

**Koneksi via Command Line (Windows / Linux CLI)**
- Di Windows: Buka Command Prompt (CMD), utility `ftp` sudah tersedia bawaan:
  ```cmd
  ftp [IP_SERVER]
  ```
- Di Linux: Jalankan perintah (pasang paket jika belum ada via `sudo apt install ftp`):
  ```bash
  ftp [IP_SERVER]
  ```

Pada capture Wireshark dengan filter `ftp`, perhatikan bahwa kredensial dikirimkan dalam bentuk plaintext murni:

![Login FileZilla Wireshark](images/wireshark-ftp-login.png)

| Perintah FTP | Keterangan |
| :--- | :--- |
| `USER [nama]` | Mengirim username autentikasi ke FTP server |
| `PASS [rahasia]` | Mengirim password autentikasi ke FTP server |

#### 1.7.4 Upload dan Download

**Upload**
Kalian dapat mendrag file ke panel remote di FileZilla Client, atau mengetik perintah `put [nama_file]` di terminal. Perintah yang dikirimkan pada control channel adalah `STOR`.

![STOR](images/wireshark-ftp-stor.png)

**Download**
Drag file dari remote ke local site, atau ketik perintah `get [nama_file]` di terminal. Perintah yang dikirimkan pada control channel adalah `RETR`.

![RETR](images/wireshark-ftp-retr.png)

---

### 1.8 Pola Protokol Jaringan Esensial

#### 1.8.1 TCP Three-Way Handshake dan Teardown
Sebelum pertukaran data TCP dimulai, koneksi dibangun melalui 3 langkah:
1. **SYN**: Client mengirim segmen dengan flag SYN aktif, Sequence Number awal (ISN = 0 relatif).
2. **SYN-ACK**: Server membalas dengan flag SYN dan ACK aktif, Sequence Number miliknya sendiri, dan Acknowledgment Number = Client ISN + 1.
3. **ACK**: Client mengonfirmasi balasan dengan flag ACK aktif, Acknowledgment Number = Server ISN + 1.

Penutupan koneksi dilakukan secara teratur melalui 4 arah menggunakan flag **FIN** dan **ACK**, atau diputus secara paksa seketika menggunakan flag **RST**.

#### 1.8.2 Resolusi Alamat dengan ARP
Address Resolution Protocol (ARP) memetakan IP logis ke MAC address fisik:
- **ARP Request**: Dikirim secara broadcast ke seluruh host di satu segmen jaringan (`ff:ff:ff:ff:ff:ff`, Opcode 1).
- **ARP Reply**: Host pemilik IP membalas langsung ke MAC address pemohon secara unicast (Opcode 2).

#### 1.8.3 Mekanisme Diagnostik ICMP
- **Echo Request (Type 8, Code 0)**: Permintaan ping dari pengirim.
- **Echo Reply (Type 0, Code 0)**: Jawaban balasan ping dari penerima.
- **Time-to-Live Exceeded (Type 11, Code 0)**: Dihasilkan oleh router transit ketika nilai TTL pada header IP turun menjadi 0, mendasari prinsip kerja utility `traceroute`.

---

## 2. GNS3

### 2.1 Apa itu GNS3?

**GNS3 (Graphical Network Simulator-3)** adalah perangkat lunak simulator jaringan berbasis visual yang mendukung emulasi perangkat nyata mulai dari router Cisco, MikroTik, hingga container Linux berbasis Docker.

GNS3 menggunakan model terdistribusi:
- **GNS3 Desktop Client**: Antarmuka pengguna grafis tempat merancang diagram topologi dan memanggil konsol terminal.
- **GNS3 VM (Server / Controller)**: Mesin virtual Linux yang menjalankan komputasi emulasi berat, bridging interface virtual (`ubridge`), dan engine Docker di lingkungan kernel terisolasi dengan akselerasi KVM.

---

### 2.2 Instalasi GNS3 VM

Unduh paket **GNS3 VM** resmi yang cocok dengan versi GNS3 Client dari [gns3.com/software/download-vm](https://www.gns3.com/software/download-vm).

#### Opsi A: VirtualBox

1. Unduh dan install [VirtualBox](https://www.virtualbox.org/) versi terbaru.
2. Unduh image GNS3 VM untuk VirtualBox dan ekstrak file `.zip` hingga memperoleh file `.ova`.
3. Buka VirtualBox, pilih **File -> Import Appliance**, arahkan ke file `.ova`.

   ![import-ova](images/vb-import-ova.png)

4. Buat host network adapter baru: **File -> Tools -> Network Manager -> Host-only Networks -> Create**. Atur IPv4 Address ke `192.168.56.1` dan Netmask `255.255.255.0`.

   ![host-network-adapter](images/vb-host-network-adapter.png)

5. Pada VM GNS3, buka **Settings -> Network**:
   - Adapter 1: Pilih **Host-only Adapter** (arahkan ke adapter yang baru dibuat).
   - Adapter 2: Pilih **NAT**.

   ![settings-network-vm](images/vb-settings-network.png)

6. Jalankan VM. Layar konsol VM akan menampilkan alamat IP Web-UI, misalnya `http://192.168.56.101:3080`.

   ![vm-running](images/vb-vm-running.png)

#### Opsi B: VMware Workstation Pro

VMware Workstation Pro kini **gratis untuk penggunaan personal dan edukasi**. Cukup mendaftar akun di Broadcom Support Portal tanpa memerlukan license key berbayar.

1. Unduh installer VMware Workstation Pro dari portal Broadcom dan pilih opsi *Personal Use*.
2. Unduh **GNS3 VM for VMware Workstation** dari situs GNS3, lalu ekstrak arsipnya.
3. Di VMware: **File -> Open**, pilih file OVA/OVF, lalu beri nama VM.

   ![import-ova-vmware](images/vmw-import-ova.png)

4. Masuk ke **Edit virtual machine settings**:
   - Pastikan Network Adapter 1 berada di **Host-only** (VMnet1) dan Adapter 2 di **NAT** (VMnet8).
   - Pada bagian **Processors**, pastikan opsi **Virtualize Intel VT-x/EPT or AMD-V/RVI** tercentang.

   ![settings-vmware](images/vmw-settings.png)

5. Jalankan VM hingga konsol menampilkan alamat IP Web-UI.

   ![vm-running-vmware](images/vmw-vm-running.png)

#### Troubleshooting Virtualisasi Hardware (VT-x, AMD-V, Hyper-V)
Jika muncul pesan error virtualisasi tidak didukung:
1. Pastikan fitur Intel VT-x atau AMD-V aktif di menu BIOS/UEFI komputer kalian.
2. Di Windows 11, nonaktifkan isolasi memori: **Windows Security -> Device Security -> Core Isolation -> Matikan Memory Integrity**.
3. Jika Hyper-V memblokir hypervisor pihak ketiga, jalankan perintah ini di PowerShell Administrator lalu reboot:
   ```powershell
   bcdedit /set hypervisorlaunchtype off
   ```

---

### 2.3 Memasukkan Image Node ke GNS3

1. Pada GNS3 Client, buka menu **Edit -> Preferences -> Docker -> Docker containers**, lalu klik **New**.

   ![insert-image-menu](images/gns3-docker-template-menu.png)

2. Pada pilihan Server type, pilih **Run this Docker container on the GNS3 VM**.
3. Pilih opsi **New image** dan masukkan nama image:
   - Rekomendasi standar: `gns3/ipterm` (berbasis Debian, sudah terpasang utility jaringan lengkap seperti `iproute2`, `ping`, `curl`, `traceroute`, `nano`).
   - Alternatif: `nevarre/gns3-debi:latest`.
4. Beri nama container: `Debian-Node`.
5. Tentukan jumlah **Network adapters** sesuai kebutuhan topologi (isi **4** untuk node router agar memiliki interface eth0 hingga eth3).
6. Biarkan bagian lain sesuai default, lalu klik **Finish** dan **Apply**.

   ![docker-template-config](images/gns3-docker-template-config.png)

7. Uji template: buat project baru (**File -> New blank project**), buka panel perangkat, tarik node baru ke workspace lembar kerja.

   ![test-node](images/gns3-test-node.png)

8. Klik kanan node lalu pilih **Start**. Akses konsol melalui **Web console** atau terminal lokal via Telnet:
   ```bash
   telnet [IP_GNS3_VM] [Port_Node]
   ```
   Untuk keluar dari sesi Telnet, tekan shortcut `Ctrl + ]` lalu ketik `quit`.

   ![akses-node](images/gns3-akses-node.png)

---

### 2.4 Instalasi dan Setup GNS3 Client

1. Unduh GNS3 Client all-in-one installer dari [gns3.com/software/download](https://www.gns3.com/software/download).
2. Jalankan installer dan pilih komponen yang dibutuhkan (GNS3 Desktop dan Wireshark).

   ![client-install](images/gns3-client-install.png)

3. Saat pertama kali dibuka, jendela Setup Wizard akan muncul. Pilih **Run appliances on a virtual machine** atau **Run appliances on a remote server**, lalu masukkan IP dan port controller GNS3 VM kalian.

   ![client-setup](images/gns3-client-setup.png)

> **Catatan keamanan:** Secara default koneksi client ke controller menggunakan HTTP port 3080. Untuk lab jaringan yang digunakan bersama, disarankan mengaktifkan enkripsi HTTPS pada pengaturan server GNS3.

---

### 2.5 Setup IP di Node

1. Pastikan node dalam kondisi berhenti (*Stop*). Klik kanan pada node, pilih **Configure**.
2. Pada tab **General settings**, klik tombol **Edit network configuration**.

   ![setup-ip](images/gns3-setup-ip.png)

3. File konfigurasi `/etc/network/interfaces` akan terbuka untuk mengatur konfigurasi IP statis atau dinamis pada interface yang digunakan.

---

### 2.6 Akses Sebuah Node ke Internet

1. Tarik node bertuliskan **NAT** dari panel perangkat ke workspace.
2. Gunakan tool **Add a Link**, hubungkan interface **NAT0** pada node NAT menuju interface **eth0** pada node Linux kalian.

   ![internet-access-link](images/gns3-internet-link.png)

3. Konfigurasikan interface `eth0` node agar meminta IP otomatis lewat DHCP:
   ```text
   auto eth0
   iface eth0 inet dhcp
   ```
4. Jalankan node, buka konsol, lalu uji koneksi dengan perintah `ping -c 3 google.com` atau `ping -c 3 8.8.8.8`.

   ![internet-access-test](images/gns3-internet-test.png)

5. Ubah nama node menjadi `Router1` melalui klik kanan -> **Change hostname**, dan ubah simbolnya menjadi router melalui klik kanan -> **Change symbol**. Node ini siap digunakan sebagai router pada topologi berikutnya.

---

### 2.7 Membuat Topologi Terintegrasi

Tambahkan node **Ethernet switch** dan beberapa node Linux, hubungkan menggunakan kabel, dan beri nama setiap perangkat:

![topologi-contoh](images/gns3-topologi-contoh.png)

#### 2.7.1 Skema Pengalamatan IP

| Perangkat | Interface | Mode | IP Address | Netmask | Gateway | Fungsi |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Router1** | `eth0` | DHCP | Otomatis dari NAT | Sesuai NAT | Otomatis | WAN (Internet) |
| | `eth1` | Static | `10.10.1.1` | `255.255.255.0` | None | Gateway LAN 1 |
| | `eth2` | Static | `10.10.2.1` | `255.255.255.0` | None | Gateway LAN 2 |
| **Client1** | `eth0` | Static | `10.10.1.2` | `255.255.255.0` | `10.10.1.1` | Host di Subnet 1 |
| **Client2** | `eth0` | Static | `10.10.2.2` | `255.255.255.0` | `10.10.2.1` | Host di Subnet 2 |

#### 2.7.2 Konfigurasi Router Linux (Multi-Homed)
Buka konfigurasi jaringan pada **Router1**:
```text
auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 10.10.1.1
    netmask 255.255.255.0

auto eth2
iface eth2 inet static
    address 10.10.2.1
    netmask 255.255.255.0
```

Konfigurasi pada **Client1** di belakang LAN 1:
```text
auto eth0
iface eth0 inet static
    address 10.10.1.2
    netmask 255.255.255.0
    gateway 10.10.1.1
```

Konfigurasi pada **Client2** di belakang LAN 2:
```text
auto eth0
iface eth0 inet static
    address 10.10.2.2
    netmask 255.255.255.0
    gateway 10.10.2.1
```

#### 2.7.3 Mengaktifkan Kernel IP Forwarding
Sistem operasi Linux secara default menonaktifkan penerusan paket antar-interface. Tanpa pengaturan ini, paket dari LAN 1 tidak akan pernah bisa melompat ke interface internet `eth0`.

Nyalakan router, buka konsol, lalu jalankan:
```bash
sysctl -w net.ipv4.ip_forward=1
```
Pastikan nilainya bernilai 1 dengan mengecek `cat /proc/sys/net/ipv4/ip_forward`.

#### 2.7.4 Konfigurasi Source NAT (iptables MASQUERADE)
Karena alamat `10.10.1.0/24` dan `10.10.2.0/24` adalah IP Private, router harus menyamarkan alamat sumber paket menjadi IP milik `eth0` saat paket keluar menuju internet:
```bash
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -m state --state ESTABLISHED,RELATED -j ACCEPT
```

> **Tips Persistensi Router:** Karena container Docker bersifat ephemeral, kalian dapat menyisipkan perintah ini langsung ke konfigurasi interface `eth0` router (`/etc/network/interfaces`) menggunakan baris awalan `up` agar otomatis dimuat setiap kali node dinyalakan ulang:
> ```text
> auto eth0
> iface eth0 inet dhcp
>     up sysctl -w net.ipv4.ip_forward=1
>     up iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
> ```

#### 2.7.5 Konfigurasi Client dan DNS Resolver
Nyalakan Client1 dan Client2. Buka konsol masing-masing lalu tambahkan DNS resolver:
```bash
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

#### 2.7.6 Verifikasi Konektivitas End-to-End
1. Cek konfigurasi IP pada setiap node dengan perintah `ip a`:

   ![cek-ip](images/gns3-cek-ip.png)

2. Uji ping dari Client1 ke gateway: `ping -c 2 10.10.1.1`.
3. Uji routing antar-subnet dari Client1 ke Client2: `ping -c 2 10.10.2.2`.
4. Uji akses internet publik dari Client1 dan Client2: `ping -c 2 8.8.8.8` dan `ping -c 2 google.com`.

   ![topologi-internet](images/gns3-topologi-internet.png)

---

### 2.8 Ketentuan, Persistensi, Tips, Trik, dan Troubleshooting

- File dan aplikasi yang diinstal di dalam root filesystem container Docker bersifat **ephemeral** (hilang saat node dihapus). Hanya direktori `/root` yang dipertahankan secara persisten oleh image seperti `gns3/ipterm`.
- Simpan seluruh skrip otomasi konfigurasi penting ke dalam folder `/root`.
- Perintah yang ingin dijalankan otomatis setiap kali membuka konsol dapat dimasukkan ke bagian bawah file `/root/.bashrc`.
- Perintah startup jaringan juga dapat dimasukkan langsung ke file `/etc/network/interfaces` menggunakan baris awalan `up`:
  ```text
  auto eth0
  iface eth0 inet dhcp
      up sysctl -w net.ipv4.ip_forward=1
      up iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  ```
- Ekspor project untuk tugas tim menggunakan menu **File -> Export portable project** (`.gns3project`).
- Jika simulasi tiba-tiba mengalami error komunikasi socket, lakukan restart pada GNS3 VM.

---

## 3. Menghubungkan Wireshark dengan GNS3

### 3.1 Capture Langsung dari Link Topologi

GNS3 memungkinkan penyadapan link virtual secara real-time langsung ke Wireshark:

1. Pada topologi yang sedang berjalan, klik kanan pada kabel link yang ingin diamati, lalu pilih **Start capture**.

2. Centang opsi **Start the capture visualization program**, lalu klik **OK**. Wireshark akan terbuka otomatis menampilkan lalu lintas data yang melintasi link tersebut secara langsung.

3. Untuk menghentikan proses sadap, klik kanan kabel yang sama lalu pilih **Stop capture**. Simpan data melalui **File -> Save** di Wireshark jika diperlukan.

---

### 3.2 Capture di Dalam Node dengan tcpdump dan TShark

Untuk menangkap paket langsung dari sudut pandang internal node tanpa GUI:

**Menggunakan tcpdump**
```bash
# Menangkap 10 paket pertama pada eth0
tcpdump -i eth0 -n -c 10

# Menyimpan paket ke file pcap di folder persisten
tcpdump -i eth0 -s 0 -w /root/hasil-capture.pcap
```

**Menggunakan TShark**
```bash
tshark -i eth0 -w /root/hasil-capture.pcap
```
Hentikan capture dengan `Ctrl + C`. File `.pcap` dapat dibaca kembali di terminal menggunakan `tshark -r /root/hasil-capture.pcap` atau disalin ke komputer host untuk dibuka pada Wireshark GUI.

---

### 3.3 Contoh Skenario Analisis: Verifikasi SNAT dan ARP

- **Analisis ARP Sebelum ICMP**: Capture link antara dua node yang baru pertama kali berkomunikasi. Saat perintah `ping` dijalankan, amati paket ARP Request (broadcast) dan ARP Reply (unicast) yang mendahului paket ICMP Echo Request pertama.
- **Verifikasi Source NAT**: Pasang live capture pada link internal (`eth1`) dan link eksternal router (`eth0`) secara bersamaan. Saat client melakukan ping ke internet (`8.8.8.8`), perhatikan perubahan IP sumber pada paket sebelum melewati router (`10.10.1.2`) dan setelah melewati router (berganti menjadi IP DHCP `eth0` router).

---

## 4. Latihan

1. Bangun topologi sederhana (2 node + 1 switch) di GNS3. Lakukan capture pada link menggunakan fitur **Start capture**, kirim perintah ping antar-node, lalu identifikasi protokol dan opcode yang muncul sebelum balasan ping pertama diterima.
2. Terapkan capture filter BPF yang hanya menangkap lalu lintas data dari salah satu IP node di topologi kalian.
3. Jalankan pengujian HTTPS dengan environment variable `SSLKEYLOGFILE` aktif pada browser komputer host. Dekripsikan trafiknya di Wireshark dan sebutkan protokol internal yang terlihat di dalam payload setelah didekripsi.
4. Siapkan server FTP dengan FileZilla Server, rekam proses login dan pengiriman file menggunakan Wireshark, lalu tunjukkan baris paket plaintext yang memuat username, password, dan instruksi transfer file.
5. Jalankan `tcpdump` atau `tshark` langsung di dalam konsol salah satu node GNS3 untuk menangkap paket ICMP tanpa menggunakan GUI, lalu buka file `.pcap` hasilnya di Wireshark komputer host.

---

## 5. Troubleshooting Common Pitfalls

| Masalah | Penyebab Utama | Solusi |
| :--- | :--- | :--- |
| **Server GNS3 VM berwarna abu-abu / Disconnected** | Perubahan alamat IP adapter atau pemblokiran firewall | Cek IP pada konsol VM dan sesuaikan di Preferences GNS3 Client. Izinkan port 3080 pada firewall. |
| **Client gagal ping ke gateway router** | Kesalahan penulisan netmask atau interface tertukar | Jalankan `ip a` di router dan client untuk memastikan interface fisik sesuai dengan konfigurasi file `/etc/network/interfaces`. |
| **Client bisa ping gateway tapi gagal ping ke 8.8.8.8** | IP forwarding belum aktif di kernel atau rule iptables belum disetel | Jalankan `sysctl -w net.ipv4.ip_forward=1` di router dan pasang rule `iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE`. |
| **Bisa ping IP publik tapi gagal ping nama domain** | File resolver DNS belum dikonfigurasi | Tambahkan DNS server ke `/etc/resolv.conf` client dengan perintah `echo "nameserver 8.8.8.8" > /etc/resolv.conf`. |
| **Paket tidak muncul saat Start Capture** | Driver Npcap bermasalah atau hak akses ubridge | Restart service Npcap pada Windows (`net stop npcap && net start npcap`), atau atur capability ubridge di Linux. |

---

## 6. Referensi

- [Dokumentasi Resmi Wireshark](https://www.wireshark.org/docs/wsug_html_chunked/)
- [Wireshark Capture Filter BPF Reference](https://www.wireshark.org/docs/wsug_html_chunked/ChCapCaptureFilterSection.html)
- [Wireshark Display Filter Reference](https://www.wireshark.org/docs/wsug_html_chunked/ChWorkBuildDisplayFilterSection.html)
- [Wireshark TLS Decryption Wiki](https://wiki.wireshark.org/TLS)
- [Dokumentasi Inti GNS3](https://docs.gns3.com/)
- [Broadcom Support Portal untuk Unduhan VMware Workstation Pro](https://knowledge.broadcom.com/external/article/368667/download-and-license-vmware-desktop-hype.html)
- [RFC 792: Internet Control Message Protocol](https://datatracker.ietf.org/doc/html/rfc792)
- [RFC 793: Transmission Control Protocol](https://datatracker.ietf.org/doc/html/rfc793)
- [RFC 959: File Transfer Protocol](https://datatracker.ietf.org/doc/html/rfc959)
- [Dokumentasi Netfilter dan iptables Linux](https://netfilter.org/documentation/)
