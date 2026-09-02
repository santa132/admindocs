# Moodle Installation from GitHub Source

## 1. Phương án khuyến nghị

Nếu muốn dùng cách cài giống file cũ, nên dùng:

```text
Ubuntu 24.04 LTS
Apache 2.4
PHP 8.3
MariaDB 10.11
Moodle 5.2.1 source từ GitHub
```

Không nên dùng Ubuntu 22.04 nếu muốn Moodle 5.2, vì Ubuntu 22.04 mặc định PHP 8.1, không đủ cho Moodle 5.2.

---

## 2. Cài package hệ thống

### Ubuntu 24.04 LTS

```bash
sudo apt update
```

Cài Apache, MariaDB, Git và tool phụ trợ:

```bash
sudo apt install -y \
  apache2 \
  mariadb-server mariadb-client \
  git unzip curl wget \
  graphviz aspell ghostscript clamav
```

Cài PHP 8.3 và extension cần cho Moodle:

```bash
sudo apt install -y \
  php8.3 \
  libapache2-mod-php8.3 \
  php8.3-cli \
  php8.3-fpm \
  php8.3-mysql \
  php8.3-curl \
  php8.3-gd \
  php8.3-intl \
  php8.3-mbstring \
  php8.3-xml \
  php8.3-xmlrpc \
  php8.3-ldap \
  php8.3-zip \
  php8.3-soap \
  php8.3-bcmath \
  php8.3-sodium \
  php8.3-opcache \
  php8.3-readline
```

Bật Apache module:

```bash
sudo a2enmod php8.3
sudo a2enmod rewrite
sudo a2enmod headers
sudo systemctl restart apache2
```

Kiểm tra PHP:

```bash
php -v
```

Kết quả nên là PHP `8.3.x`.

---

## 4. Cấu hình MariaDB

Chạy secure installation:

```bash
sudo mysql_secure_installation
```

Đăng nhập MariaDB:

```bash
sudo mysql
```

Tạo database Moodle:

```sql
CREATE DATABASE moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER 'moodle-user'@'localhost' IDENTIFIED BY 'SGPAIp@ssw0rd';

GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER
ON moodle.* TO 'moodle-user'@'localhost';

FLUSH PRIVILEGES;
EXIT;
```

Kiểm tra login:

```bash
mysql -u moodle-user -p moodle
```

Nếu login được thì DB ổn.

---

## 5. Tải Moodle source từ GitHub

### Cài Moodle latest stable 5.2

```bash
cd /opt
sudo git clone https://github.com/moodle/moodle.git
cd moodle
sudo git checkout MOODLE_502_STABLE
```

Hoặc checkout đúng tag:

```bash
cd /opt
sudo git clone https://github.com/moodle/moodle.git
cd moodle
sudo git checkout v5.2.1
```

Khuyến nghị dùng branch stable:

```text
MOODLE_502_STABLE
```

Vì sau này update minor dễ hơn:

```bash
sudo git pull
```

Copy sang web root:

```bash
sudo rsync -a /opt/moodle/ /var/www/html/moodle/
```

---

## 6. Tạo moodledata

Không đặt `moodledata` trong `/var/www/html`.

```bash
sudo mkdir -p /var/moodledata
```

Phân quyền an toàn hơn file cũ:

```bash
sudo chown -R www-data:www-data /var/moodledata
sudo chmod -R 770 /var/moodledata
```

Phân quyền source Moodle:

```bash
sudo chown -R root:www-data /var/www/html/moodle
sudo find /var/www/html/moodle -type d -exec chmod 755 {} \;
sudo find /var/www/html/moodle -type f -exec chmod 644 {} \;
```

Không nên dùng:

```bash
chmod -R 0777
```

vì rất nguy hiểm.

---

## 7. Cấu hình PHP

Sửa file:

```bash
sudo vi /etc/php/8.3/apache2/php.ini
```

Tìm và set các giá trị:

```ini
max_input_vars = 5000
memory_limit = 512M
post_max_size = 200M
upload_max_filesize = 200M
max_execution_time = 300
max_file_uploads = 100
```

Cấu hình opcache khuyến nghị:

```ini
opcache.enable = 1
opcache.memory_consumption = 256
opcache.max_accelerated_files = 20000
opcache.revalidate_freq = 60
opcache.use_cwd = 1
opcache.validate_timestamps = 1
opcache.save_comments = 1
opcache.enable_file_override = 0
```

Restart Apache:

```bash
sudo systemctl restart apache2
```

Kiểm tra PHP module:

```bash
php -m | egrep "curl|gd|intl|mbstring|mysqli|soap|xml|zip|sodium|opcache"
```

---

## 8. Cấu hình Apache port 8888 giống file cũ

### Sửa `/etc/apache2/ports.conf`

```bash
sudo vi /etc/apache2/ports.conf
```

Thêm:

```apache
Listen 8888
```

### Tạo VirtualHost riêng cho Moodle

```bash
sudo vi /etc/apache2/sites-available/moodle.conf
```

Nội dung:

```apache
<VirtualHost *:8888>
    ServerName login3.gpucluster.sutd.edu.sg
    ServerAdmin webmaster@localhost

    DocumentRoot /var/www/html

    <Directory /var/www/html/moodle>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/moodle_error.log
    CustomLog ${APACHE_LOG_DIR}/moodle_access.log combined
</VirtualHost>
```

Enable site:

```bash
sudo a2ensite moodle.conf
sudo a2enmod rewrite
sudo systemctl reload apache2
```

Kiểm tra:

```bash
sudo apache2ctl configtest
sudo systemctl status apache2
```

Mở firewall nếu cần:

```bash
sudo ufw allow 8888/tcp
```

---

## 9. Cấu hình Moodle bằng web installer

Truy cập:

```text
http://login3.gpucluster.sutd.edu.sg:8888/moodle
```

Hoặc nếu dùng IP:

```text
http://<SERVER_IP>:8888/moodle
```

Thông tin DB:

```text
Database type: MariaDB
Database host: localhost
Database name: moodle
Database user: moodle-user
Database password: CHANGE_STRONG_PASSWORD_HERE
Table prefix: mdl_
Data directory: /var/moodledata
```

Sau khi chạy installer, Moodle sẽ tạo file:

```bash
/var/www/html/moodle/config.php
```

Kiểm tra `$CFG->wwwroot`.

Ví dụ nếu dùng domain:

```php
$CFG->wwwroot = 'http://login3.gpucluster.sutd.edu.sg:8888/moodle';
```

Nếu dùng IP:

```php
$CFG->wwwroot = 'http://192.168.33.15:8888/moodle';
```

Không nên dùng lẫn IP và domain.

---

## 10. Nếu muốn tự tạo `config.php`

Bạn có thể tạo:

```bash
sudo vi /var/www/html/moodle/config.php
```

Nội dung mẫu:

```php
<?php  // Moodle configuration file

unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = 'mariadb';
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'localhost';
$CFG->dbname    = 'moodle';
$CFG->dbuser    = 'moodle-user';
$CFG->dbpass    = 'CHANGE_STRONG_PASSWORD_HERE';
$CFG->prefix    = 'mdl_';

$CFG->dboptions = array (
  'dbpersist' => 0,
  'dbport' => '',
  'dbsocket' => '',
  'dbcollation' => 'utf8mb4_unicode_ci',
);

$CFG->wwwroot   = 'http://login3.gpucluster.sutd.edu.sg:8888/moodle';
$CFG->dataroot  = '/var/moodledata';
$CFG->admin     = 'admin';

$CFG->directorypermissions = 02770;

require_once(__DIR__ . '/lib/setup.php');
```

Set quyền:

```bash
sudo chown root:www-data /var/www/html/moodle/config.php
sudo chmod 640 /var/www/html/moodle/config.php
```

---

## 11. Chạy Moodle install bằng CLI

Thay vì web installer, bạn có thể dùng CLI:

```bash
sudo -u www-data /usr/bin/php /var/www/html/moodle/admin/cli/install.php \
  --chmod=2770 \
  --lang=en \
  --wwwroot="http://login3.gpucluster.sutd.edu.sg:8888/moodle" \
  --dataroot="/var/moodledata" \
  --dbtype=mariadb \
  --dbhost=localhost \
  --dbname=moodle \
  --dbuser=moodle-user \
  --dbpass='CHANGE_STRONG_PASSWORD_HERE' \
  --fullname="EduCluster LMS" \
  --shortname="EduCluster" \
  --adminuser=admin \
  --adminpass='CHANGE_ADMIN_PASSWORD_HERE' \
  --adminemail=aimc_support@sutd.edu.sg \
  --agree-license \
  --non-interactive
```

---

## 12. Cấu hình Moodle cron

Đây là bước rất quan trọng.

```bash
sudo crontab -u www-data -e
```

Thêm dòng:

```cron
* * * * * /usr/bin/php /var/www/html/moodle/admin/cli/cron.php >/dev/null
```

Kiểm tra chạy tay:

```bash
sudo -u www-data php /var/www/html/moodle/admin/cli/cron.php
```

---

## 13. Cấu hình HTTPS nếu production

Nếu production, nên dùng HTTPS. Ví dụ với reverse proxy hoặc Apache SSL.

Nếu dùng Apache SSL trực tiếp trên port `8888`, bật module:

```bash
sudo a2enmod ssl
sudo a2enmod headers
sudo systemctl restart apache2
```

VirtualHost HTTPS mẫu:

```apache
<VirtualHost *:8888>
    ServerName login3.gpucluster.sutd.edu.sg

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/moodle.crt
    SSLCertificateKeyFile /etc/ssl/private/moodle.key

    DocumentRoot /var/www/html

    <Directory /var/www/html/moodle>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    Header always set Strict-Transport-Security "max-age=31536000"

    ErrorLog ${APACHE_LOG_DIR}/moodle_ssl_error.log
    CustomLog ${APACHE_LOG_DIR}/moodle_ssl_access.log combined
</VirtualHost>
```

Khi dùng HTTPS, `$CFG->wwwroot` nên là:

```php
$CFG->wwwroot = 'https://login3.gpucluster.sutd.edu.sg:8888/moodle';
```
```