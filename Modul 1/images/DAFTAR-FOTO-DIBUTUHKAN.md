# Daftar Foto/Screenshot yang Dibutuhkan

Status setelah update terakhir: alur instalasi & setup GNS3 (bagian 2.2–2.4) sudah pakai screenshot baru dari `images/image-baru/` dan **sudah lengkap** — tidak perlu foto tambahan untuk bagian itu. Yang masih perlu perhatian ada dua kelompok di bawah.

## Kelompok 1 — Sudah ada file-nya, tapi masih placeholder lama (perlu difoto ulang)

File-file ini masih ada di folder `images/` tapi berasal dari modul lama (misalnya `wireshark-awal.png` masih menunjukkan Wireshark versi 2.6.8, bukan versi terbaru). Ganti dengan screenshot baru **memakai nama file yang sama persis** supaya tidak perlu edit `README.md`.

### Wireshark umum

| Nama file | Deskripsi screenshot yang dibutuhkan |
|---|---|
| `wireshark-awal.png` | Tampilan awal Wireshark versi terbaru (4.6.x) saat memilih interface |
| `capture-filter-menu.png` | Kotak input capture filter di layar awal Wireshark |
| `capture-filter-contoh.png` | Hasil capture dengan filter `host 10.151.36.1` (atau IP lab yang relevan) |
| `display-filter-menu.png` | Kotak input display filter di atas daftar paket |
| `display-filter-contoh.png` | Hasil display filter `tcp.port == 80` |
| `export-objects-menu.png` | Menu File > Export Objects > HTTP |
| `export-pilih-objek.png` | Jendela pemilihan objek untuk di-export |

### Studi kasus FTP (bagian 1.7.1)

| Nama file | Deskripsi screenshot yang dibutuhkan |
|---|---|
| `fz-admin-connect.png` | FileZilla Server Administration Interface saat connect ke service |
| `fz-add-user.png` | Halaman Users, menambah user baru dengan password |
| `fz-mount-point.png` | Konfigurasi Mount Point (virtual path & native path) |
| `fz-client-connect.png` | FileZilla Client melakukan Quickconnect |
| `wireshark-ftp-login.png` | Capture dengan filter `ftp` menampilkan command `USER` dan `PASS` |
| `wireshark-ftp-stor.png` | Capture menampilkan command `STOR` (upload) |
| `wireshark-ftp-retr.png` | Capture menampilkan command `RETR` (download) |

### GNS3 — topologi (bagian 2.5–2.7)

| Nama file | Deskripsi screenshot yang dibutuhkan |
|---|---|
| `gns3-setup-ip.png` | Jendela Edit network configuration pada sebuah node |
| `gns3-internet-link.png` | Menghubungkan node ke node NAT lewat Add a Link |
| `gns3-internet-test.png` | Hasil `ping` ke google.com dari console node |
| `gns3-topologi-contoh.png` | Contoh topologi dengan router, switch, dan beberapa node |
| `gns3-cek-ip.png` | Hasil `ip a` menunjukkan IP sesuai konfigurasi di tiap node |
| `gns3-topologi-internet.png` | Semua node berhasil ping ke internet publik |

## Kelompok 2 — Belum ada sama sekali (studi kasus baru: TLS, SMTP, HTTP)

| Nama file | Deskripsi screenshot yang dibutuhkan |
|---|---|
| `tls-preferences.png` | Wireshark Preferences > Protocols > TLS dengan kolom (Pre)-Master-Secret log filename terisi |
| `tls-decrypted.png` | Paket TLS yang sudah terdekripsi, terlihat isi HTTP/2 di dalamnya |
| `wireshark-smtp-capture.png` | Capture dengan filter `smtp` menampilkan EHLO, MAIL FROM, RCPT TO, DATA |
| `mailpit-webui.png` | Web UI Mailpit (`localhost:8025`) menampilkan email uji coba yang berhasil diterima |
| `wireshark-http-capture.png` | Capture dengan filter `http` menampilkan request `GET` dan response `200 OK` |
| `wireshark-http-follow-stream.png` | Hasil Follow HTTP Stream dari request/response di atas |

**Total masih dibutuhkan: 19 file** (13 di Kelompok 1 + 6 di Kelompok 2).

> Catatan: file placeholder ini boleh dihapus setelah semua gambar di atas sudah dilengkapi.
