# Step 5: Rollback Plan

## When to trigger Rollback?

- Database migration fails with unrecoverable SQL/PHP exceptions.
- The OAuth plugin fails to function and cannot be debugged quickly.
- JupyterHub fails to connect to Moodle after completing production steps.
- Moodle fails to boot or displays permanent internal server errors.

> ⏱️ **Target RTO:** Restore original system state within **15-20 minutes**.

---

## 5.1 Rollback Database

```bash
# Verify the backup file exists
ls -lh /mnt/nfs-ehn1/EduCluster/backups/moodle_backup_*.sql

# Select the target backup file (replace YYYYMMDD_HHMMSS)
BACKUP_FILE="moodle_backup_<YYYYMMDD_HHMMSS>.sql"

# Drop the current database and restore from backup
sudo mysql -u root -p <<EOF
DROP DATABASE IF EXISTS moodle;
CREATE DATABASE moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EOF

sudo mysql -u root -p moodle < /mnt/nfs-ehn1/EduCluster/backups/${BACKUP_FILE}

echo "Database restored from backup!"
```

---

## 5.2 Rollback Moodle Code Files

```bash
# Restore files from backup directory
sudo rsync -av --delete \
  --exclude='config.php' \
  /mnt/nfs-ehn1/EduCluster/backups/moodle_files_<YYYYMMDD_HHMMSS>/ \
  /var/www/html/moodle/

# Fix permissions
sudo chown -R www-data:www-data /var/www/html/moodle
sudo chmod -R 0755 /var/www/html/moodle
sudo chmod 0640 /var/www/html/moodle/config.php

# Verify rolled-back version
cat /var/www/html/moodle/version.php | grep release
```

**Expected Output:** `$release  = '4.0.2 ...'`

---

## 5.3 Rollback Git Repository (if deploying from /opt/moodle)

```bash
cd /opt/moodle

# Checkout the previous stable branch
sudo git checkout MOODLE_402_STABLE

# Re-deploy to web directory
sudo rsync -av --delete \
  --exclude='config.php' \
  /opt/moodle/ /var/www/html/moodle/

sudo chown -R www-data:www-data /var/www/html/moodle
```

---

## 5.4 Rollback JupyterHub config.yaml

```bash
# Restore previous production config.yaml
BACKUP_DATE="<YYYYMMDD>"  # Provide backup date

cp /path/to/config.yaml.backup_${BACKUP_DATE} /path/to/config.yaml

# Re-apply config
helm upgrade --cleanup-on-fail \
  --install hub jupyterhub/jupyterhub \
  --namespace hub \
  --create-namespace \
  --values config.yaml \
  --version 2.0

# Monitor pods
kubectl --namespace=hub get pod -w
```

---

## 5.5 Disable Maintenance Mode and Verify

```bash
# Turn off maintenance mode
sudo -u www-data php /var/www/html/moodle/admin/cli/maintenance.php --disable

sudo systemctl restart apache2
```

### Post-rollback Verification

```bash
# Check version file
cat /var/www/html/moodle/version.php | grep release
# → Must return: 4.0.2

# Check apache status
sudo systemctl status apache2
```

Access: `http://login2.gpucluster.sutd.edu.sg:8888/moodle`
→ Logging in should function normally.

Access: `http://login2.gpucluster.sutd.edu.sg/hub`
→ JupyterHub must redirect to Moodle and allow authentication.

---

## 5.6 Document Incident Details

Once rollback is successful, please document:

```
Rollback Date: ___________
Rollback Reason: ___________
Errors encountered:
  - ___________
  - ___________
Follow-up actions:
  - Verify and debug issues on test node before attempting again.
  - See: https://moodle.org/mod/forum/discuss.php?d=461894
```

---

## ✅ Rollback Checklist

- [ ] Maintenance mode enabled
- [ ] Database restored from backup
- [ ] Code files rolled back to 4.0.2
- [ ] JupyterHub config.yaml restored
- [ ] JupyterHub redeployed
- [ ] Maintenance mode disabled
- [ ] Moodle 4.0.2 functions normally
- [ ] JupyterHub OAuth authentication functions normally
- [ ] Incident details recorded for investigation
