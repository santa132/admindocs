# Step 4: Upgrade Moodle Production (192.168.33.15)

## Prerequisites
> ✅ Steps 1, 2, and 3 have been completed and verified successfully.
> 
> ✅ OAuth Plugin works correctly with Moodle 4.5.12.
> 
> ✅ JupyterHub OAuth flow has been fully verified.

---

## Expected Downtime

| Phase | Duration |
|-------|----------|
| Maintenance mode + Backup | ~10 mins |
| Verify PHP environment | ~5 mins |
| Git checkout + file copy | ~5 mins |
| Database migration | ~15-30 mins |
| Plugin reinstall | ~10 mins |
| Verify & test | ~10 mins |
| **Total** | **~50-70 mins** |

> ⚠️ Perform this upgrade during **non-class hours** or **weekends** to minimize user impact.

---

## 4.1 Check PHP Environment BEFORE Upgrade

> 🆕 Added after discovering `max_input_vars` issues during staging tests (aimc-ehn1).
> Moodle 4.5 strictly requires `max_input_vars >= 5000` — if not set, the upgrade stops at the Environment check. You should fix this **before** enabling maintenance mode to save downtime.

```bash
# Identify the active php.ini file for FPM and CLI
php -i | grep "Loaded Configuration File"
php-fpm8.1 -i | grep "Loaded Configuration File"   # or check the pool config file

# Check the current value (typically commented out, e.g. ;max_input_vars = 1000)
grep -n "max_input_vars" /etc/php/8.1/fpm/php.ini /etc/php/8.1/cli/php.ini
```

If it is commented or < 5000, modify it directly (substitute the line numbers based on the grep output):

```bash
sudo sed -i 's/^;max_input_vars = 1000/max_input_vars = 5000/' /etc/php/8.1/fpm/php.ini
sudo sed -i 's/^;max_input_vars = 1000/max_input_vars = 5000/' /etc/php/8.1/cli/php.ini

# Verify changes
grep -n "^max_input_vars" /etc/php/8.1/fpm/php.ini /etc/php/8.1/cli/php.ini
# Expected: max_input_vars = 5000 in both files

sudo systemctl restart php8.1-fpm
sudo systemctl restart apache2
```

---

## 4.2 Enable Maintenance Mode on Moodle Production

```bash
# SSH into production server
ssh <user>@192.168.33.15

# Enable maintenance mode
sudo -u www-data php /var/www/html/moodle/admin/cli/maintenance.php --enable

# Verify maintenance mode status
sudo -u www-data php /var/www/html/moodle/admin/cli/maintenance.php
```

→ Accessing `http://login2.gpucluster.sutd.edu.sg:8888/moodle` should now display **"Maintenance Mode"**.

---

## 4.3 Backup Database Production

```bash
# Backup database (Mandatory!)
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)

sudo mysqldump \
  -u root -p \
  --single-transaction \
  --routines \
  --triggers \
  moodle > /tmp/moodle_backup_${BACKUP_DATE}.sql

# Verify backup file size
ls -lh /tmp/moodle_backup_${BACKUP_DATE}.sql

# Move backup to a secure storage (NFS storage)
sudo cp /tmp/moodle_backup_${BACKUP_DATE}.sql \
  /mnt/nfs-ehn1/EduCluster/backups/moodle_backup_${BACKUP_DATE}.sql
```

---

## 4.4 Backup Moodle Files

```bash
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)

# Backup Moodle source directory
sudo cp -R /var/www/html/moodle /mnt/nfs-ehn1/EduCluster/backups/moodle_files_${BACKUP_DATE}

# Backup config.php (Crucial!)
sudo cp /var/www/html/moodle/config.php /mnt/nfs-ehn1/EduCluster/backups/config_${BACKUP_DATE}.php

# Backup moodledata directory
sudo tar -czf /mnt/nfs-ehn1/EduCluster/backups/moodledata_${BACKUP_DATE}.tar.gz \
  /var/moodledata/

echo "Backup completed: ${BACKUP_DATE}"
```

---

## 4.5 Upgrade Moodle Code to 4.5.12

```bash
cd /opt/moodle

# Fetch all recent branches
sudo git fetch origin

# Check current branch
sudo git branch -a | grep MOODLE

# Checkout to 4.5 stable branch
sudo git branch --track MOODLE_405_STABLE origin/MOODLE_405_STABLE
sudo git checkout MOODLE_405_STABLE

# Pull the latest code (4.5.12)
sudo git pull

# Verify version details
cat /opt/moodle/version.php | grep -E "release|version"
```

**Expected Output:**
```
$version  = 2024100712.05;
$release  = '4.5.12+ (Build: XXXXXXXX)';
```

---

## 4.6 Deploy Code to Web Directory

```bash
# Sync files to web directory. MUST use leading slash '/' to exclude root config.php only
sudo rsync -av --delete \
  --exclude='/config.php' \
  /opt/moodle/ /var/www/html/moodle/

# Verify config.php remains intact (not overwritten)
ls -la /var/www/html/moodle/config.php

# Verify no stale config.php files exist in subdirectories
find /var/www/html/moodle -name "config.php" -newer /var/www/html/moodle/version.php

# Fix permissions
sudo chown -R www-data:www-data /var/www/html/moodle
sudo chmod -R 0755 /var/www/html/moodle
sudo chmod 0640 /var/www/html/moodle/config.php
```

---

## 4.7 Chạy Database Migration

```bash
# Clear old caches before upgrade to avoid autoloader namespace conflicts
sudo rm -rf /var/moodledata/localcache/* /var/moodledata/cache/* /var/moodledata/muc/*

# Run upgrade script (performs database schema modifications)
sudo -u www-data php /var/www/html/moodle/admin/cli/upgrade.php --non-interactive

# Monitor execution (takes approximately 15-30 minutes)
```

**Expected End Output:**
```
Upgrade completed successfully.
```

> ❌ If errors occur → STOP, **do not disable maintenance mode**, and check `05_rollback_en.md`.
> If upgrade complains about Environment checks (e.g. `max_input_vars`) and you missed step 4.1,
> go back to 4.1, fix PHP config, and run this upgrade command again (it is safe to re-run).

---

## 4.8 Disable Maintenance Mode

> Only perform this after step 4.7 successfully prints **"Upgrade completed successfully"**.
> Turning off maintenance mode when database migration is broken can lock up the system.

```bash
# Disable maintenance mode
sudo -u www-data php /var/www/html/moodle/admin/cli/maintenance.php --disable

# If the site still displays "under maintenance" screen, verify CLI maintenance flag:
ls -la /var/moodledata/climaintenance.html
# If this file exists, delete it manually:
sudo rm -f /var/moodledata/climaintenance.html
```

---

## 4.9 Cài lại OAuth Plugin

```bash
# Extract OAuth plugin to Moodle directory
sudo unzip /path/to/oauth_gn4.zip -d /var/www/html/moodle/local/
sudo chown -R www-data:www-data /var/www/html/moodle/local/oauth
sudo chmod -R 0755 /var/www/html/moodle/local/oauth

# Install/upgrade the plugin inside Moodle database
sudo -u www-data php /var/www/html/moodle/admin/cli/upgrade.php --non-interactive
```

### Reconfigure OAuth Client

1. Log in to Moodle: `http://login2.gpucluster.sutd.edu.sg:8888/moodle`
2. Go to **Site administration** → **Server** → **OAuth provider settings**
3. Click **Add new client** (or edit existing one if present)

| Field | Value |
|-------|---------|
| **client_id** | `JupyterHub` |
| **Redirect URI** | `http://login2.gpucluster.sutd.edu.sg/hub/oauth_callback` |

4. **Copy the new `client_secret`!** ← Required in step 4.10

---

## 4.10 Update JupyterHub config.yaml

```bash
# Edit config.yaml - point back to production Moodle
vi /path/to/config.yaml
```

Update variables:

```yaml
hub:
  config:
    GenericOAuthenticator:
      client_id: JupyterHub
      # Replace with the new client_secret from Moodle production (step 4.9)
      client_secret: <NEW_CLIENT_SECRET_FROM_PRODUCTION>
      oauth_callback_url: http://login2.gpucluster.sutd.edu.sg/hub/oauth_callback

      # Point URLs back to PRODUCTION Moodle (upgraded)
      authorize_url: http://login2.gpucluster.sutd.edu.sg:8888/moodle/local/oauth/login.php?client_id=jupyterhub&response_type=code
      token_url: http://login2.gpucluster.sutd.edu.sg:8888/moodle/local/oauth/token.php
      userdata_url: http://login2.gpucluster.sutd.edu.sg:8888/moodle/local/oauth/user_info.php
      scope:
        - user_info
    Authenticator:
      admin_users:
        - admin
    JupyterHub:
      authenticator_class: generic-oauth
  networkPolicy:
    enabled: false
```

```bash
# Redeploy JupyterHub
helm upgrade --cleanup-on-fail \
  --install hub jupyterhub/jupyterhub \
  --namespace hub \
  --create-namespace \
  --values config.yaml \
  --version 2.0

# Watch deployment status
kubectl --namespace=hub get pod -w
```

---

## 4.11 Verification After Upgrade

### Check Moodle Version

```bash
# Check version directly via PHP CLI
sudo -u www-data php -r "define('CLI_SCRIPT',1); require('/var/www/html/moodle/config.php'); echo \$CFG->release . PHP_EOL;"

# Verify upgrade status — should report that system is up-to-date
sudo -u www-data php /var/www/html/moodle/admin/cli/upgrade.php --non-interactive 2>&1 | tail -5
```

Navigate to: `http://login2.gpucluster.sutd.edu.sg:8888/moodle`
→ Release version must be **4.5.12**.

### Test JupyterHub OAuth Integration

1. Go to `http://login2.gpucluster.sutd.edu.sg/hub`
2. Login → redirects to Moodle.
3. Login on Moodle → authorize → redirects back to JupyterHub.
4. Spawn a Notebook server.

### Check Moodle Cron Execution

```bash
# Execute cron job manually to verify
sudo -u www-data php /var/www/html/moodle/admin/cli/cron.php
```

### Verify Security Fixes

- Go to **Site administration** → **Security** → **Security overview**
- Ensure CVE-2024-45689 warning is resolved.

### Troubleshooting blank pages

```bash
sudo tail -50 /var/log/apache2/error.log
```

---

## ✅ Checklist Step 4 - Production Upgrade

**Pre-upgrade:**
- [ ] `max_input_vars >= 5000` set in FPM and CLI ini configurations, restarted services
- [ ] Users notified about maintenance
- [ ] Maintenance mode is active
- [ ] Database backup complete and verified (`/mnt/nfs-ehn1/EduCluster/backups/`)
- [ ] Source files backup complete

**Upgrade:**
- [ ] Git checkout MOODLE_405_STABLE successful
- [ ] `version.php` reports 4.5.12
- [ ] `rsync` used `--exclude='/config.php'` (leading slash verified)
- [ ] Verified no stale `config.php` files exist
- [ ] Database migration successful with "Upgrade completed successfully" output
- [ ] OAuth plugin reinstalled

**Post-upgrade:**
- [ ] New `client_secret` updated in `config.yaml`
- [ ] JupyterHub redeployed
- [ ] Maintenance mode deactivated (verified `climaintenance.html` is removed)
- [ ] Logged into Moodle successfully
- [ ] JupyterHub OAuth flow works
- [ ] Jupyter Notebook server spawns successfully

**→ Finished! Update system logs with upgrade date and version.**
