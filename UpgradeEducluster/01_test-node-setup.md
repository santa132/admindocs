# Step 1: Installing Moodle 4.5.12 on Test Node

## Test Node Information

> Replace `192.168.33.3` with the actual IP of the test node (e.g., `192.168.33.20`)

| Parameter | Value |
|-----------|---------|
| **IP** | `192.168.33.3` |
| **Port** | `8889` (avoids port conflict with production :8888) |
| **Test URL** | `http://192.168.33.3:8889/moodle` |
| **DB Name** | `moodle_test` |
| **DB User** | `moodle-test-user` |

---

## 1.1 Update System

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 1.2 Install LAMP Stack

### Install Apache2

```bash
sudo apt install apache2 -y
sudo systemctl enable apache2
sudo systemctl start apache2
```

### Install MariaDB

```bash
sudo apt install mariadb-server mariadb-client -y
sudo systemctl enable mariadb
sudo mysql_secure_installation
```

> **Note:** When running `mysql_secure_installation`:
> - Set root password: `Yes`
> - Remove anonymous users: `Yes`
> - Disallow root login remotely: `Yes`
> - Remove test database: `Yes`
> - Reload privilege tables: `Yes`

### Install PHP 8.1 and Required Extensions

```bash
sudo add-apt-repository ppa:ondrej/php -y
sudo apt-get update

sudo apt install php8.1 libapache2-mod-php8.1 \
  php8.1-fpm php8.1-cli php8.1-mysql \
  php8.1-curl php8.1-gd php8.1-intl \
  php8.1-xml php8.1-xmlrpc php8.1-ldap \
  php8.1-zip php8.1-soap php8.1-mbstring \
  php8.1-pspell \
  graphviz aspell ghostscript clamav -y

sudo a2enmod php8.1
```

### Verify Software Versions

```bash
php -v
mysql --version
apache2 -v
```

---

## 1.3 Install Moodle 4.5.12 from Git

```bash
cd /opt/

# Clone Moodle repo
sudo git clone https://github.com/moodle/moodle.git
cd moodle

# Checkout branch 4.5 stable (Moodle 4.5.12 LTS)
sudo git branch --track MOODLE_405_STABLE origin/MOODLE_405_STABLE
sudo git checkout MOODLE_405_STABLE

# Pull the latest code (4.5.12)
sudo git pull

# Verify version
cat version.php | grep "\$version"
```

> **Expected Output:** `$version  = 2024100712.00;` (corresponds to 4.5.12)

### Copy Moodle to Web Directory

```bash
cd /opt/
sudo cp -R moodle /var/www/html/
sudo chmod -R 0755 /var/www/html/moodle
sudo chown -R www-data:www-data /var/www/html/moodle

# Create data directory
sudo mkdir /var/moodledata_test
sudo chown -R www-data /var/moodledata_test
sudo chmod -R 0770 /var/moodledata_test
```

---

## 1.4 Create Moodle Database

```bash
sudo mysql -u root -p
```

```sql
-- Create database
CREATE DATABASE moodle_test DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create user
CREATE USER 'moodle-test-user'@'localhost' IDENTIFIED BY 'TestP@ssw0rd';

-- Grant privileges
GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER
  ON moodle_test.*
  TO 'moodle-test-user'@'localhost';

FLUSH PRIVILEGES;
exit;
```

---

## 1.5 Configure Apache2

Edit the virtual host configuration file:

```bash
sudo vi /etc/apache2/sites-available/000-default.conf
```

Content:

```apache
Listen 8889
<VirtualHost *:8889>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

Enable required modules:

```bash
sudo a2enmod rewrite
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo systemctl restart apache2
```

---

## 1.6 Configure PHP

```bash
sudo vi /etc/php/8.1/apache2/php.ini
```

Find and modify the following lines:

```ini
max_input_vars = 5000
upload_max_filesize = 512M
post_max_size = 512M
max_execution_time = 300
memory_limit = 256M
```

```bash
sudo systemctl restart apache2
```

---

## 1.7 Create config.php for Moodle

```bash
sudo cp /var/www/html/moodle/config-dist.php /var/www/html/moodle/config.php
sudo vi /var/www/html/moodle/config.php
```

Content of `config.php`:

```php
<?php  // Moodle configuration file

unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = 'mariadb';
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'localhost';
$CFG->dbname    = 'moodle_test';
$CFG->dbuser    = 'moodle-test-user';
$CFG->dbpass    = 'TestP@ssw0rd';
$CFG->prefix    = 'mdl_';
$CFG->dboptions = array (
  'dbpersist' => 0,
  'dbport' => '',
  'dbsocket' => '',
  'dbcollation' => 'utf8mb4_unicode_ci',
);

// Replace 192.168.33.3 with the actual IP of the test node
$CFG->wwwroot   = 'http://192.168.33.3:8889/moodle';
$CFG->dataroot  = '/var/moodledata_test';
$CFG->admin     = 'admin';

$CFG->directorypermissions = 0770;

require_once(__DIR__ . '/lib/setup.php');
```

---

## 1.8 Complete Installation via Web Interface

### Open your browser and navigate to:

```
http://192.168.33.3:8889/moodle
```

Moodle will automatically execute the installation wizard:

1. **Confirm paths** → Next
2. **Choose database driver**: `MariaDB (native/mariadb)` → Next
3. **Database settings**: Fill in the DB credentials created in step 1.4 → Next
4. **Server checks**: Everything must be ✅ PASS → Next
5. **License**: Confirm → Continue
6. **Install** → Wait for database tables creation (~5-10 minutes)
7. **Admin account setup**:
   - Username: `admin`
   - Password: `<strong password>`
   - Email: `aimc_support@sutd.edu.sg`
8. **Site name**: `EduCluster Moodle Test`

### Alternatively, install via CLI (much faster):

```bash
sudo -u www-data php /var/www/html/moodle/admin/cli/install.php \
  --lang=en \
  --wwwroot="http://192.168.33.3:8889/moodle" \
  --dataroot="/var/moodledata_test" \
  --dbtype=mariadb \
  --dbhost=localhost \
  --dbname=moodle_test \
  --dbuser=moodle-test-user \
  --dbpass="TestP@ssw0rd" \
  --adminpass="Admin@TestP@ss" \
  --adminemail="aimc_support@sutd.edu.sg" \
  --non-interactive \
  --agree-license
```

---

## 1.9 Verify Installation Success

```bash
# Check Moodle version
cat /var/www/html/moodle/version.php | grep release

# Check Apache status
sudo systemctl status apache2

# Check DB connection
mysql -u moodle-test-user -p moodle_test -e "SHOW TABLES;" | head -20
```

**Expected Results:**
- `$release  = '4.5.12+ (Build: ...)` in version.php
- Apache2 is `active (running)`
- Multiple `mdl_*` tables are populated in the database

---

## ✅ Checklist Step 1

- [ ] LAMP stack installed
- [ ] PHP 8.1 is functioning
- [ ] MariaDB is functioning
- [ ] Moodle 4.5.12 code checked out from Git
- [ ] Database `moodle_test` created
- [ ] Apache2 is listening on port `8889`
- [ ] Navigated to `http://192.168.33.3:8889/moodle` successfully
- [ ] Successfully logged in as admin

**→ Next step: `02_oauth-plugin-test_en.md`**
