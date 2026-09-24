# 3. Reverse Proxy

## Outline

- [3. Reverse Proxy](#3-reverse-proxy)
  - [3.1 Pengantar Reverse Proxy](#31-pengantar-reverse-proxy)
    - [3.1.1 Pengertian (Forward vs Reverse Proxy)](#311-pengertian-forward-vs-reverse-proxy)
    - [3.1.2 Cara Kerja](#312-cara-kerja)
    - [3.1.3 Manfaat dalam Arsitektur Modern](#313-manfaat-dalam-arsitektur-modern)
    - [3.1.4 Penjelasan in Simple Terms (intie inti)](#314-penjelasan-in-simple-terms-intie-inti)
  - [3.2 Skenario dan Arsitektur Aplikasi](#32-skenario-dan-arsitektur-aplikasi)
    - [3.2.1 Topologi Jaringan](#321-topologi-jaringan)
    - [3.2.2 Komponen dan Peran](#322-komponen-dan-peran)
  - [3.3 Implementasi Arsitektur Dasar](#33-implementasi-arsitektur-dasar)
    - [3.3.1 Menyiapkan Backend Server Statis](#331-menyiapkan-backend-server-statis)
    - [3.3.2 Menyiapkan Backend Server Dinamis](#332-menyiapkan-backend-server-dinamis)
    - [3.3.3 Mengkonfigurasi Reverse Proxy](#333-mengkonfigurasi-reverse-proxy)
  - [3.4 Pengujian dan Verifikasi](#34-pengujian-dan-verifikasi)
    - [3.4.1 Why?](#341-why)
    - [3.4.2 Menganalisis Hasil Pengujian](#342-menganalisis-hasil-pengujian)
  - [3.5 Skalabilitas dan Konfigurasi Lanjutan](#35-skalabilitas-dan-konfigurasi-lanjutan)
    - [3.5.1 Menyiapkan Server Replika](#351-menyiapkan-server-replika)
    - [3.5.2 Memperbarui Konfigurasi Reverse Proxy](#352-memperbarui-konfigurasi-reverse-proxy)
  - [3.6 Pengenalan Load Balancing](#36-pengenalan-load-balancing)
    - [3.6.1 Konsep dan Metode di Nginx](#361-konsep-dan-metode-di-nginx)
    - [3.6.2 Contoh Implementasi pada Arsitektur Kita](#362-contoh-implementasi-pada-arsitektur-kita)
  - [3.7 Pengujian Beban (Load Testing)](#37-pengujian-beban-load-testing)
    - [3.7.1 Pengenalan Apache Benchmark (ab)](#371-pengenalan-apache-benchmark-ab)
    - [3.7.2 Menganalisis Hasil Load Test dari Skrip](#372-menganalisis-hasil-load-test-dari-skrip)
    - [What to do?](#what-to-do)

## 3.1 Pengantar Reverse Proxy

Bagian ini akan memperkenalkan konsep dasar di balik Reverse Proxy, membedakannya dari Forward Proxy, menjelaskan cara kerjanya, dan menyoroti (anjay) manfaat utamanya dalam arsitektur aplikasi modern.

### 3.1.1 Pengertian (Forward vs Reverse Proxy)

Sebelum mengenal Reverse Proxy lebih jauh, perlu diketahui bahwa Reverse Proxy dan Proxy Service, seperti `Forward Proxy` adalah 2 hal yang berbeda dari cara kerjanya.

- **Forward Proxy**: Bertindak atas nama **klien**. Ketika kita atau jaringan internal kita menggunakan forward proxy untuk mengakses internet, server tujuan (misalnya, `google.com`) melihat permintaan datang dari server proxy, bukan dari kita. Ini berguna untuk menyembunyikan IP klien, melewati batasan jaringan internal, atau memfilter konten yang diakses oleh pengguna.

- **Reverse Proxy**: Bertindak atas nama **server**. Klien mengirim permintaan ke reverse proxy (yang terlihat seperti server biasa bagi klien), dan proxy tersebut yang secara internal menentukan server backend mana yang akan menangani permintaan itu. Klien tidak pernah tahu server backend mana yang sebenarnya melayaninya. Ini adalah komponen sisi server yang melindungi dan mengelola akses ke server-server aplikasi.

### 3.1.2 Cara Kerja

Reverse Proxy berada di antara klien (seperti browser pengguna) dan satu atau lebih server backend. Alur kerjanya adalah sebagai berikut:

1.  Klien mengirimkan permintaan ke domain publik (misalnya, `www.it06.com`). Permintaan ini diterima oleh Reverse Proxy.
2.  Reverse Proxy memeriksa permintaan tersebut (misalnya, path URL seperti `/app/` atau `/static/`) dan, berdasarkan aturannya, meneruskannya ke server backend yang sesuai.
3.  Server backend (misalnya, server aplikasi atau server file statis) memproses permintaan dan mengirimkan respons kembali ke Reverse Proxy.
4.  Reverse Proxy menerima respons tersebut, dan bisa melakukan modifikasi jika perlu (seperti kompresi), lalu mengirimkannya kembali ke klien.
5.  Dari sudut pandang klien, seluruh proses ini terlihat seolah-olah mereka berkomunikasi langsung dengan satu server tunggal.

### 3.1.3 Manfaat dalam Arsitektur Modern

Menggunakan Reverse Proxy memberikan banyak keuntungan strategis dalam desain sistem, misalkan:

-   `Load Balancing`: Mendistribusikan permintaan secara merata ke beberapa server backend. Ini mencegah satu server menjadi kelebihan beban, meningkatkan ketersediaan aplikasi, dan memungkinkan skalabilitas horizontal (menambah lebih banyak server saat trafik meningkat).
-   `Peningkatan Keamanan`: Menyembunyikan topologi jaringan internal dan alamat IP server backend dari dunia luar. Reverse Proxy dapat bertindak sebagai lapisan pertahanan pertama, menangani serangan seperti DDoS dan memfilter permintaan berbahaya sebelum mencapai server aplikasi yang krusial.
-   `Caching`: Menyimpan salinan respons dari server backend (misalnya, halaman web atau gambar yang sering diakses) dan menyajikannya langsung ke klien untuk permintaan berikutnya. Ini secara drastis mengurangi beban pada server backend dan mempercepat waktu respons bagi pengguna.
-   `SSL/TLS Termination`: Reverse Proxy dapat menangani semua proses enkripsi dan dekripsi SSL/TLS. Ini menyederhanakan konfigurasi di server backend (yang dapat berkomunikasi melalui HTTP biasa di jaringan internal yang aman) dan memusatkan manajemen sertifikat SSL.
-   `Fleksibilitas Arsitektur`: Memudahkan penambahan, penghapusan, atau pembaruan server backend tanpa mengganggu layanan. Karena klien hanya terhubung ke alamat reverse proxy, perubahan di belakang layar tidak akan terlihat oleh pengguna.

### 3.1.4 Penjelasan in Simple Terms (intie inti)

Bayangin kita datang ke sebuah gedung besar, misalnya kantor pusat e-commerce "Fundraise ARA". Di lobi ada satu orang resepsionis ramah, namanya Mba Proxy. Nah, tugas Mba Proxy ini mirip banget sama reverse proxy. Begini ceritanya:

1. Kita datang, bilang, "Halo, mau ketemu tim promo."  
   → Mba Proxy cek daftar tamu: "Boleh, silakan naik lift B lantai 3."

2. Kita nggak tahu (dan nggak perlu tahu) kalau di lantai 3 itu ruangannya rame: ada tim promo A, tim promo B, tim promo C. Yang kita tahu cuma: datang ke resepsionis, selesai.

3. Ternyata tim promo B lagi sibuk. Mba Proxy langsung ubah arah: "Lift B penuh, yuk lewat lift C aja, tujuannya sama kok."  
   → Jadi kita nggak nunggu lama. Itu namanya `load-balancing`.

4. Sambil nunggu lift, Mba Proxy tawarkan air mineral atau brosur promo bulan lalu (versi lama tapi masih valid). Kita ambil aja, nggak usah naik-turun lantai.  
   → Ini fungsi `caching`.

5. Kalau ada tamu iseng bawa surat ancaman atau mau masuk seenaknya, Mba Proxy yang kroscek dulu: "Maaf, surat izinnya kurang." Dia tolak di lobi, jadi nggak sampai mengganggu kerjaan tim di atas.  
   → Ini peran `keamanan & DDoS protection`.

6. Kantor mau ganti interior? Tim promo pindah ruangan? Kita tetap datang ke lobi yang sama, Mba Proxy yang urus belakangnya. Kita nggak pernah tahu kalau kemarin ruangannya 303, sekarang jadi 502.  
   → Fleksibilitas arsitektur: ganti server tanpa *downtime*.

Jadi, reverse proxy itu Mba Proxy-nya dunia maya: satu pintu masuk, ngatur tamu, bagi kerjaan, kasih kemasan cepat, dan jagain keamanan. Kita cukup ingat alamat gedungnya, urusan di dalamnya serahkan sis resepsionis.

Intinya, reverse proxy itu "tukang antar" yang berdiri di depan gerbang server. Dia yang nerima tamu (*request*), terus bawa ke ruang mana yang pas. Beda cerita sama forward proxy, dia malah bantu klien buat keluar rumah.

## 3.2 Skenario dan Arsitektur Aplikasi

Pada bagian ini, kita akan mendefinisikan arsitektur spesifik yang akan kita bangun dan implementasikan. Memahami topologi jaringan dan peran masing-masing komponen adalah kunci sebelum kita mulai menulis konfigurasi.

### 3.2.1 Topologi Jaringan

![Topologi Jaringan](../Reverse%20Proxy/img/newtopo.png)

Dari topologi di atas, kita dapat melihat:
-   **Eru**: Bertindak sebagai *router* atau titik distribusi utama yang menghubungkan dua segmen jaringan.
-   **Switch1 & Switch2**: Masing-masing menciptakan segmen jaringan lokal (LAN) yang terpisah.
-   Server-server kita terhubung ke *switch* ini, memisahkan server statis dan dinamis ke dalam sub-jaringan yang berbeda.

### 3.2.2 Komponen dan Peran

Setiap server dalam topologi kita memiliki nama dan peran yang spesifik, layaknya komponen dalam sebuah aplikasi dunia nyata.

-   **Simulasi Aktivitas Klien**:
    -   **Peran**: Mensimulasikan aktivitas *end user* yang mengakses aplikasi.
    -   **Implementasi**: Dalam modul ini, aktivitas klien tidak berasal dari browser, melainkan dari **program klien** yang dieksekusi oleh skrip `test.sh`. Skrip ini bertindak sebagai *test runner* yang menjalankan:
        -   **`lynx`**: Sebuah browser berbasis teks yang berperan sebagai program klien untuk memeriksa konten halaman web.
        -   **`ab` (Apache Benchmark)**: Sebuah *tool* yang berperan sebagai program klien untuk mengirimkan banyak permintaan secara bersamaan guna menguji beban server.
    -   Skrip `test.sh` ini akan dijalankan dari server `Varda` untuk memulai semua pengujian.

-   **Reverse Proxy (`Varda`)**:
    -   **Peran**: Pintu gerbang utama (*gateway*) aplikasi kita. Semua trafik dari luar akan masuk melalui server ini. Varda akan memeriksa setiap permintaan dan merutekannya ke server backend yang tepat.
    -   **Skrip Konfigurasi**: `var1.sh` dan `var2.sh`.

-   **Backend Server Statis (`Melkor`)**:
    -   **Peran**: Server yang dioptimalkan khusus untuk menyajikan konten statis seperti file HTML, gambar, CSS, dan JavaScript. Nginx sangat efisien untuk tugas ini karena tidak memerlukan pemrosesan yang kompleks.
    -   **Skrip Konfigurasi**: `mel1.sh`.

-   **Backend Server Dinamis (`Ulmo`)**:
    -   **Peran**: Server yang bertugas menjalankan logika aplikasi. Dalam kasus ini, `Ulmo` akan menggunakan PHP-FPM untuk mengeksekusi skrip PHP dan menghasilkan konten dinamis berdasarkan permintaan.
    -   **Skrip Konfigurasi**: `ulm1.sh`.

-   **Backend Server Replika (`Manwe`)**:
    -   **Peran**: Server ini adalah duplikat dari server dinamis (`Ulmo`). Tujuannya adalah untuk demonstrasi skalabilitas. Dalam skenario produksi, beberapa server replika seperti `Manwe` akan digunakan di belakang *load balancer* untuk mendistribusikan beban kerja.
    -   **Skrip Konfigurasi**: `man1.sh`.

Sangat baik. Sekarang kita akan masuk ke bagian implementasi, di mana kita akan mengkonfigurasi setiap server satu per satu.

---

## 3.3 Implementasi Arsitektur Dasar

Pada bagian ini, kita akan membangun tiga komponen inti dari arsitektur kita: server statis (`Melkor`), server dinamis (`Ulmo`), dan reverse proxy (`Varda`). Kita akan mengikuti alur `mel1.sh` → `ulm1.sh` → `var1.sh` untuk memastikan setiap *dependency* terpenuhi sebelum melanjutkan (**urutan penting banget wok**).

### 3.3.1 Menyiapkan Backend Server Statis
Server `Melkor` akan kita siapkan terlebih dahulu. Tujuannya adalah membuat server Nginx yang mampu menyajikan file statis dan menampilkan daftar file dalam direktori (*autoindex*).

*   **Instalasi Nginx:**

    Langkah pertama adalah memperbarui *package* dan menginstal Nginx.
    ```bash
    apt-get update -y
    apt-get install -y nginx
    ```

*   **Konfigurasi Resolusi Nama Lokal (Hosts):**

    Agar server lain dapat menemukan `Melkor` menggunakan nama domain `static.it06.com`, kita tambahkan entri ke file `/etc/hosts`.
    ```bash
    grep -q 'static.it06.com' /etc/hosts || echo "192.219.1.2 static.it06.com" >> /etc/hosts
    ```

*   **Pembuatan Direktori dan Konten Web:**

    Kita siapkan direktori root untuk web dan mengisinya dengan beberapa file contoh.
    ```bash
    mkdir -p /var/www/static/annals
    cat > /var/www/static/index.html <<'HTML'
    <!doctype html><title>Static Origin - Melkor</title><h1>Hello from Melkor</h1>
    HTML
    cat > /var/www/static/annals/readme.txt <<'TXT'
    Autoindex aktif. Ini folder annals (listing).
    TXT
    ```

*   **Konfigurasi Server Block Nginx:**

    Buat file konfigurasi Nginx untuk mendefinisikan bagaimana server akan merespons permintaan.
    ```bash
    cat > /etc/nginx/sites-available/static.conf <<'NGINX'
    server {
        listen 80;
        server_name static.it06.com;
        root /var/www/static;
        index index.html;
        location /annals/ { autoindex on; }
    }
    NGINX
    ```
    Konfigurasi ini memberitahu Nginx untuk merespons pada domain `static.it06.com` dan mengaktifkan `autoindex` untuk direktori `/annals/`.

*   **Aktivasi Konfigurasi dan Start Nginx:**

    Aktifkan situs baru dengan membuat *symbolic link*, hapus konfigurasi default, periksa sintaks, dan mulai layanan Nginx.
    ```bash
    ln -sf /etc/nginx/sites-available/static.conf /etc/nginx/sites-enabled/static.conf
    rm -f /etc/nginx/sites-enabled/default
    nginx -t
    service nginx start
    ```

***

**Skrip Lengkap: `mel1.sh`**
```bash
#!/bin/bash
echo "Install Nginx"
apt-get update -y
apt-get install -y nginx

echo "Tambahkan hosts (agar nama lokal resolve)"
grep -q 'static.it06.com' /etc/hosts || echo "192.219.1.2 static.it06.com" >> /etc/hosts

echo "Web root & konten"
mkdir -p /var/www/static/annals
cat > /var/www/static/index.html <<'HTML'
<!doctype html><title>Static Origin - Melkor</title><h1>Hello from Melkor</h1>
HTML
cat > /var/www/static/annals/readme.txt <<'TXT'
Autoindex aktif. Ini folder annals (listing).
TXT

echo "Server block origin statis"
cat > /etc/nginx/sites-available/static.conf <<'NGINX'
server {
    listen 80;
    server_name static.it06.com;
    root /var/www/static;
    index index.html;
    location /annals/ { autoindex on; }
}
NGINX
ln -sf /etc/nginx/sites-available/static.conf /etc/nginx/sites-enabled/static.conf
rm -f /etc/nginx/sites-enabled/default

echo "Test & start Nginx"
nginx -t
service nginx start
```

### 3.3.2 Menyiapkan Backend Server Dinamis
Selanjutnya adalah server `Ulmo`. Server ini akan menangani logika aplikasi menggunakan PHP.

*   **Instalasi Nginx + PHP-FPM:**

    Kita membutuhkan Nginx dan PHP-FPM. Perintah ini akan mencoba menginstal `php8.4-fpm`.
    ```bash
    apt-get update -y
    apt-get install -y nginx php8.4-fpm
    ```

*   **Konfigurasi Resolusi Nama Lokal (Hosts):**

    Tambahkan entri untuk `app.it06.com` agar dapat dijangkau melalui nama domain.
    ```bash
    grep -q 'app.it06.com' /etc/hosts || echo "192.219.2.3 app.it06.com" >> /etc/hosts
    ```

*   **Pembuatan Direktori dan Konten PHP:**

    Siapkan direktori root dan buat dua file PHP sederhana.
    ```bash
    mkdir -p /var/www/app
    cat > /var/www/app/index.php <<'PHP'
    <?php echo "<h1>App Origin - Ulmo</h1>"; ?>
    PHP
    cat > /var/www/app/about.php <<'PHP'
    <?php echo "<h2>About Ulmo</h2>"; ?>
    PHP
    ```

*   **Konfigurasi Server Block Nginx dengan PHP-FPM:**

    Konfigurasi ini akan meneruskan semua permintaan file `.php` ke layanan PHP-FPM.
    ```bash
    cat > /etc/nginx/sites-available/app.conf <<'NGINX'
    server {
        listen 80;
        server_name app.it06.com;
        root /var/www/app;
        index index.php;

        location = /about { return 301 /about/; }
        location = /about/ { rewrite ^ /about.php last; }

        location / {
            try_files $uri $uri/ /index.php?$args;
        }

        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/run/php/php8.4-fpm.sock;
        }
    }
    NGINX
    ```
    Perhatikan blok `location ~ \.php$`, di mana `fastcgi_pass` menjadi jembatan antara Nginx dan PHP.

*   **Aktivasi Konfigurasi dan Start Layanan:**

    Aktifkan situs, periksa sintaks, lalu mulai layanan PHP-FPM dan Nginx.
    ```bash
    ln -sf /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/app.conf
    rm -f /etc/nginx/sites-enabled/default
    nginx -t
    service php8.4-fpm start || service php-fpm start
    service nginx start
    ```

***

**Skrip Lengkap: `ulm1.sh`**
```bash
#!/bin/bash
echo "Install Nginx + PHP-FPM"
apt-get update -y
apt-get install -y nginx php8.4-fpm || apt-get install -y nginx php-fpm

echo "Tambahkan hosts (nama lokal)"
grep -q 'app.it06.com' /etc/hosts || echo "192.219.2.3 app.it06.com" >> /etc/hosts

echo "Web root & contoh PHP"
mkdir -p /var/www/app
cat > /var/www/app/index.php <<'PHP'
<?php echo "<h1>App Origin - Ulmo</h1>"; ?>
PHP
cat > /var/www/app/about.php <<'PHP'
<?php echo "<h2>About Ulmo</h2>"; ?>
PHP

echo "Server block PHP-FPM + rewrite /about"
cat > /etc/nginx/sites-available/app.conf <<'NGINX'
server {
    listen 80;
    server_name app.it06.com;
    root /var/www/app;
    index index.php;

    location = /about { return 301 /about/; }
    location = /about/ { rewrite ^ /about.php last; }

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }
}
NGINX
ln -sf /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/app.conf
rm -f /etc/nginx/sites-enabled/default

echo "Test & start"
nginx -t
service php8.4-fpm start || service php-fpm start
service nginx start
```

### 3.3.3 Mengkonfigurasi Reverse Proxy
Sekarang kita akan mengkonfigurasi `Varda` untuk bertindak sebagai reverse proxy. Server ini akan menjadi satu-satunya titik akses publik.

*   **Instalasi Nginx dan Tools Pengujian:**

    Kita membutuhkan `nginx`, `apache2-utils` (untuk `htpasswd`), `lynx` (untuk pengujian), dan `apache2-bin` (untuk `ab`).
    ```bash
    apt-get update -y
    apt-get install -y nginx apache2-utils lynx apache2-bin
    ```

*   **Konfigurasi Hosts di Sisi Proxy:**

    `Varda` harus mengetahui alamat IP dari semua server backend dan domain utamanya agar dapat merutekan trafik dengan benar.
    ```bash
    add() { grep -q "$1" /etc/hosts || echo "$1" >> /etc/hosts; }
    add "192.219.2.2 www.it06.com"
    add "192.219.1.2 static.it06.com"
    add "192.219.2.3 app.it06.com"
    ```

*   **Konfigurasi Server Block Reverse Proxy:**

    Ini adalah inti dari reverse proxy. Kita akan membuat file konfigurasi yang merutekan permintaan berdasarkan path URL.
    ```bash
    cat > /etc/nginx/sites-available/www.conf <<'NGINX'
    log_format with_realip '$remote_addr - $remote_user [$time_local] '
                          '"$request" $status $body_bytes_sent '
                          '"$http_referer" "$http_user_agent" '
                          'realip=$http_x_real_ip fwd=$http_x_forwarded_for';

    server {
        listen 80;
        server_name www.it06.com;
        access_log /var/log/nginx/sirion_access.log with_realip;

        location ^~ /admin/ {
            auth_basic "Admin Area";
            auth_basic_user_file /etc/nginx/.htpasswd;
            default_type text/plain;
            return 200 "Admin OK\n";
        }

        location /static/ {
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_pass http://static.it06.com/;
        }

        location /app/ {
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_pass http://app.it06.com/;
        }
    }
    NGINX
    ```
    -   **`location /static/`**: Meneruskan permintaan ke `Melkor`.
    -   **`location /app/`**: Meneruskan permintaan ke `Ulmo`.
    -   **`proxy_pass`**: Perintah kunci untuk meneruskan permintaan.
    -   **`proxy_set_header`**: Memastikan informasi klien asli (seperti IP) diteruskan ke server backend.

*   **Pembuatan User untuk Basic Authentication**
    Gunakan `htpasswd` untuk membuat user `admin` dengan password `admin123`.
    ```bash
    htpasswd -bc /etc/nginx/.htpasswd admin admin123
    ```

*   **Aktivasi Konfigurasi dan Start Nginx**
    ```bash
    ln -sf /etc/nginx/sites-available/www.conf /etc/nginx/sites-enabled/www.conf
    rm -f /etc/nginx/sites-enabled/default
    nginx -t
    service nginx start
    ```

***

**Skrip Lengkap: `var1.sh`**
```bash
#!/bin/bash
echo "Install Nginx + tools uji"
apt-get update -y
apt-get install -y nginx apache2-utils lynx apache2-bin

echo "Hosts agar Varda resolve origin & host kanonik"
add() { grep -q "$1" /etc/hosts || echo "$1" >> /etc/hosts; }
add "192.219.2.2 www.it06.com"
add "192.219.1.2 static.it06.com"
add "192.219.2.3 app.it06.com"

echo "Default server: redirect ke host kanonik"
cat > /etc/nginx/sites-available/00-redirect.conf <<'NGINX'
server {
    listen 80 default_server;
    server_name _;
    if ($host != 'www.it06.com') { return 301 http://www.it06.com$request_uri; }
    return 301 http://www.it06.com$request_uri;
}
NGINX
ln -sf /etc/nginx/sites-available/00-redirect.conf /etc/nginx/sites-enabled/00-redirect.conf

echo "Reverse proxy + Basic Auth untuk /admin/"
cat > /etc/nginx/sites-available/www.conf <<'NGINX'
log_format with_realip '$remote_addr - $remote_user [$time_local] '
                      '"$request" $status $body_bytes_sent '
                      '"$http_referer" "$http_user_agent" '
                      'realip=$http_x_real_ip fwd=$http_x_forwarded_for';

server {
    listen 80;
    server_name www.it06.com;
    access_log /var/log/nginx/sirion_access.log with_realip;

    # Normalisasi /admin -> /admin/
    location = /admin { return 301 /admin/; }

    # Proteksi admin
    location ^~ /admin/ {
        auth_basic "Admin Area";
        auth_basic_user_file /etc/nginx/.htpasswd;
        default_type text/plain;
        return 200 "Admin OK\n";
    }

    # /static -> Melkor
    location /static/ {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://static.it06.com/;
    }

    # /app -> Ulmo
    location /app/ {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://app.it06.com/;
    }
}
NGINX
ln -sf /etc/nginx/sites-available/www.conf /etc/nginx/sites-enabled/www.conf

echo "Buat user Basic Auth"
htpasswd -bc /etc/nginx/.htpasswd admin admin123

echo "Bersihkan site default & start"
rm -f /etc/nginx/sites-enabled/default
nginx -t
service nginx start
```

## 3.4 Pengujian dan Verifikasi

Pada bagian ini, kita akan menggunakan skrip `test.sh` untuk melakukan serangkaian pengujian otomatis. Skrip ini akan dijalankan dari server `Varda` dan akan bertindak sebagai *test runner* yang mengeksekusi program klien `lynx` dan `ab` untuk mensimulasikan berbagai jenis permintaan.

### 3.4.1 *Why?*

Skrip `test.sh` dirancang untuk menguji beberapa aspek kunci dari arsitektur kita:
1.  **Konektivitas Langsung ke Server Backend**: Memastikan setiap server backend (`Melkor` dan `Ulmo`) dapat dijangkau dan merespons dengan benar secara independen.
2.  **Fungsionalitas Reverse Proxy**: Memverifikasi bahwa `Varda` berhasil merutekan permintaan ke server backend yang benar berdasarkan path URL.
3.  **Mekanisme Autentikasi**: Menguji bahwa halaman yang diproteksi (`/admin/`) benar-benar memerlukan kredensial yang valid.
4.  **Performa Dasar**: Melakukan pengujian beban sederhana untuk membandingkan responsivitas antara konten statis dan dinamis.

**FYI:** Bisa coba per line untul yang ini yaa

### 3.4.2 Menganalisis Hasil Pengujian

> CATATAN: Cukup gunakan `lynx (website)` jika ingin melihat semacam GUI

*   **Pengujian Konektivitas Langsung ke Backend:**

    Langkah ini penting untuk *troubleshooting*. Jika pengujian ini gagal, kita tahu masalahnya ada di server backend itu sendiri, bukan di reverse proxy.
    ```bash
    lynx -dump http://static.it06.com/ | head
    lynx -dump http://static.it06.com/annals/ | head
    lynx -dump http://app.it06.com/ | head
    lynx -dump http://app.it06.com/about | head
    ```
    -   **Ekspektasi**: Perintah-perintah ini harus berhasil menampilkan konten dari `Melkor` ("Hello from Melkor" dan daftar file) dan `Ulmo` ("App Origin - Ulmo" dan "About Ulmo").

![contest](../Reverse%20Proxy/img/contesting.png)

*   **Pengujian Fungsionalitas Reverse Proxy:**

    Ini adalah pengujian inti. Kita mengirim permintaan ke `Varda` (`www.it06.com`) dan berharap Varda akan meneruskannya dengan benar.
    ```bash
    lynx -dump http://www.it06.com/static/ | head
    lynx -dump http://www.it06.com/app/ | head
    ```
    -   **Ekspektasi**: Permintaan ke `/static/` harus mengembalikan konten dari `Melkor`, dan permintaan ke `/app/` harus mengembalikan konten dari `Ulmo`. Jika berhasil, ini membuktikan bahwa `proxy_pass` berfungsi.

![rptest](../Reverse%20Proxy/img/rptesting.png)

*   **Pengujian Basic Authentication:**

    Kita menguji skenario sukses dan gagal untuk memastikan lapisan keamanan kita bekerja.
    ```bash
    lynx -auth=madrid:kingofyurop -dump http://www.it06.com/admin/ | head
    lynx -auth=admin:admin123 -dump http://www.it06.com/admin/ | head
    ```
    -   **Ekspektasi**: Permintaan pertama dengan kredensial salah harus gagal (biasanya dengan status `401 Unauthorized`). Permintaan kedua dengan kredensial yang benar (`admin:admin123`) harus berhasil dan menampilkan "Admin OK".

![bauth](../Reverse%20Proxy/img/basicauth.png)
![bauths](../Reverse%20Proxy/img/basicauth2.png)

*   **Pengujian Beban Sederhana:**

    Menggunakan Apache Benchmark (`ab`) untuk mengirim 100 permintaan dengan 10 koneksi bersamaan.
    ```bash
    ab -n 100 -c 10 http://www.it06.com/app/
    ab -n 100 -c 10 http://www.it06.com/static/
    ```
    -   **Ekspektasi**: Lihat metrik `Requests per second` pada output. Nilai untuk `/static/` akan jauh lebih tinggi daripada `/app/`, yang menunjukkan efisiensi Nginx dalam menyajikan konten statis dibandingkan dengan konten dinamis yang memerlukan pemrosesan PHP.

***

**Skrip Lengkap: `test.sh`**
```bash
#!/usr/bin/env bash
echo "Test origin statis & dinamis"
lynx -dump http://static.it06.com/ | head
lynx -dump http://static.it06.com/annals/ | head
lynx -dump http://app.it06.com/ | head
lynx -dump http://app.it06.com/about | head

echo "Test reverse proxy path-based"
lynx -dump http://www.it06.com/static/ | head
lynx -dump http://www.it06.com/app/ | head

echo "Test Basic Auth (gagal & berhasil)"
lynx -auth=bad:bad -dump http://www.it06.com/admin/ | head
lynx -auth=admin:admin123 -dump http://www.it06.com/admin/ | head

echo "ApacheBench (ringkas; aman utk demo)"
ab -n 100 -c 10 http://www.it06.com/app/
ab -n 100 -c 10 http://www.it06.com/static/
```

## 3.5 Skalabilitas dan Konfigurasi Lanjutan

Pada bagian ini, kita akan menambahkan server replika (`Manwe`) sebagai langkah pertama menuju skalabilitas horizontal. Selain itu, kita akan melakukan beberapa perbaikan pada konfigurasi reverse proxy (`Varda`) untuk membuatnya lebih kuat (wong menangan iki bolo) dan sesuai dengan praktik terbaik.

### 3.5.1 Menyiapkan Server Replika

Untuk menangani beban yang lebih tinggi pada aplikasi dinamis, kita tidak bisa hanya mengandalkan satu server (`Ulmo`). Oleh karena itu, kita akan menyiapkan server `Manwe` sebagai kloning atau replika dari `Ulmo`.

*   **Instalasi Nginx + PHP-FPM:**

    Langkah ini sama dengan saat menyiapkan `Ulmo`.
    ```bash
    apt-get update -y
    apt-get install -y nginx php8.4-fpm || apt-get install -y nginx php-fpm
    ```

*   **Pembuatan Konten Berbeda:**

    Kita sengaja membuat konten yang sedikit berbeda. Tujuannya adalah agar nanti saat kita mengimplementasikan *load balancing*, kita bisa dengan jelas melihat server mana (`Ulmo` atau `Manwe`) yang sedang merespons permintaan.
    ```bash
    mkdir -p /var/www/app
    cat > /var/www/app/index.php <<'PHP'
    <?php echo "<h1>App Replica - Manwe</h1>"; ?>
    PHP
    cat > /var/www/app/about.php <<'PHP'
    <?php echo "<h2>About Manwe (replica)</h2>"; ?>
    PHP
    ```

*   **Konfigurasi Server Block:**

    Konfigurasinya hampir identik dengan `Ulmo`. Perhatikan bahwa `server_name` diatur ke `_`, yang berarti server ini akan merespons permintaan apa pun yang masuk tanpa mencocokkan nama host tertentu. Ini cocok untuk server backend yang berada di belakang reverse proxy.
    ```bash
    cat > /etc/nginx/sites-available/app-replica.conf <<'NGINX'
    server {
        listen 80;
        server_name _;
        root /var/www/app;
        index index.php;
        location = /about { return 301 /about/; }
        location = /about/ { rewrite ^ /about.php last; }
        location / { try_files $uri $uri/ /index.php?$args; }
        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/run/php/php8.4-fpm.sock;
        }
    }
    NGINX
    ```

*   **Aktivasi dan start Layanan**
    ```bash
    ln -sf /etc/nginx/sites-available/app-replica.conf /etc/nginx/sites-enabled/app-replica.conf
    rm -f /etc/nginx/sites-enabled/default
    nginx -t
    service php8.4-fpm start || service php-fpm start
    service nginx start
    ```
**Catatan Penting**: Setelah menjalankan skrip ini, `Manwe` sudah aktif dan berjalan, tetapi belum menerima trafik apa pun dari `Varda`. `Manwe` hanya dalam keadaan siaga, siap untuk ditambahkan ke dalam konfigurasi *load balancing*.

***

**Skrip Lengkap: `man1.sh`**
```bash
#!/bin/bash
echo "Install Nginx + PHP-FPM"
apt-get update -y
apt-get install -y nginx php8.4-fpm || apt-get install -y nginx php-fpm

echo "Web root & konten berbeda (biar efek LB terlihat)"
mkdir -p /var/www/app
cat > /var/www/app/index.php <<'PHP'
<?php echo "<h1>App Replica - Manwe</h1>"; ?>
PHP
cat > /var/www/app/about.php <<'PHP'
<?php echo "<h2>About Manwe (replica)</h2>"; ?>
PHP

echo "Server block"
cat > /etc/nginx/sites-available/app-replica.conf <<'NGINX'
server {
    listen 80;
    server_name _;
    root /var/www/app;
    index index.php;
    location = /about { return 301 /about/; }
    location = /about/ { rewrite ^ /about.php last; }
    location / { try_files $uri $uri/ /index.php?$args; }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }
}
NGINX
ln -sf /etc/nginx/sites-available/app-replica.conf /etc/nginx/sites-enabled/app-replica.conf
rm -f /etc/nginx/sites-enabled/default

nginx -t
service php8.4-fpm start || service php-fpm start
service nginx start
```
***

### 3.5.2 Memperbarui Konfigurasi Reverse Proxy

Seiring berkembangnya sistem, konfigurasi awal sering kali perlu diperbaiki. Skrip `var2.sh` adalah versi perbaikan (*refactoring*) dari `var1.sh`, yang menerapkan beberapa praktik terbaik.

**Perbaikan Utama**:
1.  **Nama Host Abstrak**: Menggunakan nama `lindon.it06.com` dan `vingilot.it06.com` sebagai alias untuk IP server backend di file `/etc/hosts`. Ini adalah praktik yang baik karena memisahkan logika perutean (di `nginx.conf`) dari detail infrastruktur (di `/etc/hosts`). Jika IP server backend berubah, kita hanya perlu mengubah satu baris di `/etc/hosts`, tanpa menyentuh konfigurasi Nginx yang berpotensi kompleks.
2.  **Basic Auth yang Fungsional**: Pada `var1.sh`, lokasi `/admin/` hanya mengembalikan teks "Admin OK". Pada `var2.sh`, lokasi ini diperbaiki agar setelah autentikasi berhasil, Nginx benar-benar menyajikan konten dari direktori `/var/www/admin/`. Ini adalah implementasi yang jauh lebih realistis.

***

**Skrip Lengkap: `var2.sh`**
```bash
#!/bin/bash

echo "Pastikan resolusi nama upstream tersedia di Varda"
/bin/grep -q 'lindon.it06.com' /etc/hosts || echo '192.219.1.2 lindon.it06.com static.it06.com' >> /etc/hosts
/bin/grep -q 'vingilot.it06.com' /etc/hosts || echo '192.219.2.3 vingilot.it06.com app.it06.com' >> /etc/hosts

echo "Siapkan utilitas htpasswd"
apt-get update -y
apt-get install -y apache2-utils

echo "Siapkan konten halaman admin yang diproteksi"
mkdir -p /var/www/admin
cat > /var/www/admin/index.html <<'HTML'
<!doctype html><title>Admin</title><h1>Admin OK</h1><p>Hanya terlihat jika Basic Auth sukses.</p>
HTML

echo "Tuliskan server kanonik (redirect semua host/IP ke www.it06.com)"
cat > /etc/nginx/sites-available/00-redirect.conf <<'NGINX'
server {
    listen 80 default_server;
    server_name _;
    if ($host != 'www.it06.com') { return 301 http://www.it06.com$request_uri; }
    return 301 http://www.it06.com$request_uri;
}
NGINX
ln -sf /etc/nginx/sites-available/00-redirect.conf /etc/nginx/sites-enabled/00-redirect.conf

echo "Tuliskan virtual host utama www.it06.com (reverse proxy + Basic Auth benar)"
cat > /etc/nginx/sites-available/www.conf <<'NGINX'
log_format with_realip '$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent '
                      '"$http_referer" "$http_user_agent" realip=$http_x_real_ip fwd=$http_x_forwarded_for';

server {
    listen 80;
    server_name www.it06.com;
    access_log /var/log/nginx/sirion_access.log with_realip;

    # Normalisasi /admin -> /admin/
    location = /admin { return 301 /admin/; }

    # Basic Auth (tanpa 'return 200' supaya auth benar-benar terjadi)
    location ^~ /admin/ {
        auth_basic "Admin Area";
        auth_basic_user_file /etc/nginx/.htpasswd;
        alias /var/www/admin/;
        index index.html;
    }

    # /static -> Melkor (via alias 'lindon')
    location /static/ {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://lindon.it06.com/;
    }

    # /app -> Ulmo (via alias 'vingilot')
    location /app/ {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://vingilot.it06.com/;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/www.conf /etc/nginx/sites-enabled/www.conf

echo "Buat user Basic Auth"
htpasswd -bc /etc/nginx/.htpasswd admin admin123

echo "Hapus site default bila ada"
rm -f /etc/nginx/sites-enabled/default

echo "Test & reload nginx"
nginx -t && service nginx reload
```

## 3.6 Pengenalan Load Balancing

Setelah menyiapkan server replika (`Manwe`), kita tidak bisa memanfaatkannya begitu saja. Kita memerlukan sebuah mekanisme untuk mendistribusikan permintaan yang masuk antara server asli (`Ulmo`) dan server replika (`Manwe`). Mekanisme inilah yang disebut *Load Balancing*. Reverse proxy Nginx memiliki fungsionalitas *load balancer* yang sangat kuat dan mudah dikonfigurasi.

### 3.6.1 Konsep dan Metode di Nginx

*Load balancing* adalah teknik untuk menyebarkan beban kerja (dalam hal ini, permintaan HTTP) ke beberapa sumber daya komputasi (server). Tujuannya adalah untuk mengoptimalkan penggunaan sumber daya, memaksimalkan *throughput*, meminimalkan waktu respons, dan menghindari kelebihan beban pada satu server tunggal, yang pada akhirnya meningkatkan keandalan dan ketersediaan aplikasi.

Nginx mengimplementasikan ini melalui modul `upstream`. Anda mendefinisikan sebuah grup server, lalu mengarahkan `proxy_pass` ke grup tersebut, bukan ke satu IP server.

Nginx mendukung beberapa metode (algoritma) *load balancing*:
-   **Round Robin (default)**: Ini adalah metode paling sederhana. Permintaan didistribusikan secara bergantian ke setiap server dalam grup. Jika ada tiga server, permintaan pertama ke server 1, kedua ke server 2, ketiga ke server 3, keempat kembali ke server 1, dan seterusnya.
-   **Least Connections**: Permintaan baru akan dikirim ke server yang memiliki jumlah koneksi aktif paling sedikit pada saat itu. Metode ini sangat berguna jika durasi pemrosesan permintaan bervariasi, karena ia menghindari pengiriman permintaan baru ke server yang masih sibuk dengan permintaan yang berat.
-   **IP Hash**: Dengan metode ini, Nginx akan menghitung nilai *hash* dari alamat IP klien. Hasil *hash* ini menentukan server mana yang akan menangani permintaan klien tersebut. Ini memastikan bahwa permintaan dari klien yang sama akan selalu diarahkan ke server yang sama. Ini berguna untuk aplikasi yang memerlukan *session persistence* (di mana data sesi pengguna disimpan di server tertentu).

### 3.6.2 Contoh Implementasi pada Arsitektur Kita

Meskipun skrip kita tidak secara otomatis mengimplementasikan *load balancing*, arsitektur yang kita bangun sangat siap untuk itu. Untuk mendistribusikan trafik aplikasi dinamis antara `Ulmo` dan `Manwe`, kita hanya perlu memodifikasi file konfigurasi `www.conf` di server `Varda`.

Berikut adalah contoh bagaimana konfigurasinya akan terlihat:

1.  **Dapatkan IP Address `Manwe`**: Pertama, Anda perlu mengetahui alamat IP dari server `Manwe`. Mari kita asumsikan IP-nya adalah `192.219.1.3`.

2.  **Modifikasi `www.conf` di `Varda`**: Ubah file `/etc/nginx/sites-available/www.conf` menjadi seperti ini:

    ```nginx
    # Definisikan grup server backend untuk aplikasi dinamis
    # Grup ini kita beri nama 'app_backend'
    upstream app_backend {
        # Metode default adalah round-robin, jadi tidak perlu ditulis
        # Untuk metode lain, tambahkan direktif di sini (misal: least_conn; atau ip_hash;)
        
        server 192.219.2.3; # IP Ulmo (atau vingilot.it06.com)
        server 192.219.1.3; # IP Manwe
    }

    server {
        listen 80;
        server_name www.it06.com;
        # ... konfigurasi lain seperti log dan admin ...

        # Lokasi /static/ tidak berubah, tetap ke satu server
        location /static/ {
            proxy_pass http://lindon.it06.com/;
            # ... proxy headers ...
        }

        # Lokasi /app/ sekarang diarahkan ke grup upstream
        location /app/ {
            # Arahkan proxy ke grup upstream, bukan ke satu server
            proxy_pass http://app_backend/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
    ```

Dengan konfigurasi di atas, setiap kali ada permintaan baru ke `www.it06.com/app/`, Nginx di `Varda` akan secara bergantian meneruskannya ke `Ulmo` dan `Manwe`. Jika Anda mencoba mengakses halaman tersebut berulang kali, Anda akan melihat respons berganti antara "App Origin - Ulmo" dan "App Replica - Manwe", membuktikan bahwa *load balancing* sedang berjalan.

## 3.7 Pengujian Beban (Load Testing)

Setelah membangun dan mengkonfigurasi arsitektur kita, langkah terakhir adalah mengukur kinerjanya. *Load Testing* (Pengujian Beban) adalah proses mensimulasikan beban pengguna yang tinggi pada sistem untuk melihat bagaimana sistem tersebut berperilaku. Tujuannya adalah untuk mengidentifikasi batas kemampuan sistem, menemukan *bottleneck*, dan memastikan sistem dapat menangani trafik sesuai ekspektasi.

### 3.7.1 Pengenalan Apache Benchmark (ab)

Untuk pengujian beban, kita akan menggunakan **Apache Benchmark (`ab`)**, sebuah alat baris perintah yang sederhana namun sangat efektif untuk mengukur performa server web HTTP. Alat ini sudah terinstal di `Varda` melalui skrip `var1.sh` (sebagai bagian dari paket `apache2-utils` atau `apache2-bin`).

Cara kerja `ab` adalah dengan mengirimkan sejumlah besar permintaan ke URL target dan kemudian melaporkan metrik kinerjanya. Opsi dasar yang paling sering digunakan adalah:
-   `-n` *(number)*: Jumlah total permintaan yang akan dikirim selama pengujian.
-   `-c` *(concurrency)*: Jumlah permintaan yang dikirim secara bersamaan pada satu waktu. Nilai ini mensimulasikan jumlah pengguna yang mengakses situs secara serentak.

Sebagai contoh, perintah `ab -n 1000 -c 100 http://example.com/` akan mengirim total 1000 permintaan, dengan 100 permintaan berjalan secara paralel pada setiap saat hingga total 1000 tercapai.

### 3.7.2 Menganalisis Hasil Load Test dari Skrip

Skrip `test.sh` kita sudah menyertakan pengujian beban sederhana untuk membandingkan performa antara *endpoint* statis dan dinamis.

Mari kita lihat kembali bagian pengujian tersebut:
```bash
ab -n 100 -c 10 http://www.it06.com/app/
ab -n 100 -c 10 http://www.it06.com/static/
```

Saat Anda menjalankan perintah ini, `ab` akan menghasilkan laporan yang detail. Metrik paling penting untuk diperhatikan adalah:

-   **`Requests per second`**: Ini adalah *throughput* server. Metrik ini menunjukkan berapa banyak permintaan yang mampu dilayani oleh server setiap detiknya. **Semakin tinggi nilainya, semakin baik performanya.**
-   **`Time per request`**: Rata-rata waktu yang dibutuhkan untuk melayani satu permintaan. **Semakin rendah nilainya, semakin baik performanya.**

![abtest](../Reverse%20Proxy/img/ab-testing.png)


### What to do?

> Find a way agar dapat melakukan test load balancing dan Manwe bekerja sesuai semestinya