# Step 2: Install & Test OAuth Plugin on Test Node

## Objectives
Confirm that the OAuth Plugin (`oauth_gn4.zip`) functions correctly with **Moodle 4.5.12**, ensuring JupyterHub can authenticate users through Moodle after the upgrade.

---

## 2.1 Install OAuth Plugin

### Method 1: Upload via Web Interface (Recommended)

1. Log in to Moodle test: `http://192.168.33.3:8889/moodle`
2. Go to **Site administration** → **Plugins** → **Install plugins**
3. Upload the file `oauth_gn4.zip` (available inside `/EduCluster/oauth_gn4.zip`)
4. Click **Install plugin from the ZIP file**
5. Confirm and complete installation

### Method 2: Manual Copy via CLI

```bash
# Copy ZIP file to test node
scp /path/to/oauth_gn4.zip <user>@192.168.33.3:~/

# SSH into test node
ssh <user>@192.168.33.3

# Extract to Moodle local directory
sudo unzip ~/oauth_gn4.zip -d /var/www/html/moodle/local/
sudo chown -R www-data:www-data /var/www/html/moodle/local/oauth
sudo chmod -R 0755 /var/www/html/moodle/local/oauth

# Install/upgrade plugin via CLI
sudo -u www-data php /var/www/html/moodle/admin/cli/upgrade.php --non-interactive
```

---

## 2.2 Verify Plugin Installation

On Moodle web:
1. Go to **Site administration** → **Plugins** → **Plugins overview**
2. Search for **"OAuth provider"** in the list
3. Status must show `Enabled` ✅

Or check via URL:
```
http://192.168.33.3:8889/moodle/local/oauth/login.php
```
→ It should not return a 404 error, indicating the plugin is recognized.

---

## 2.3 Configure OAuth Client for JupyterHub

1. Go to **Site administration** → **Server** → **OAuth provider settings**
2. Click **Add new client**
3. Fill in details:

| Field | Value |
|-------|---------|
| **client_id** | `JupyterHub` |
| **client_secret** | *(auto-generated - write this down!)* |
| **Redirect URI (callback URL)** | `http://login2.gpucluster.sutd.edu.sg/hub/oauth_callback` |
| **Grant type** | `Authorization Code` |
| **Scope** | `user_info` |

4. Click **Save changes**
5. **Copy and save the `client_secret`** — this will be used for testing JupyterHub.

---

## 2.4 Verify OAuth Endpoints Functionality

Test endpoints via `curl` or browser:

```bash
# Test login endpoint (should return redirect, not 404/500)
curl -I "http://192.168.33.3:8889/moodle/local/oauth/login.php?client_id=JupyterHub&response_type=code"

# Test token endpoint (should return JSON error, not 404)
curl -X POST "http://192.168.33.3:8889/moodle/local/oauth/token.php"

# Test userinfo endpoint (should return auth error, not 404)
curl "http://192.168.33.3:8889/moodle/local/oauth/user_info.php"
```

**Expected Results:**
- `login.php` → HTTP 302/303 redirect (OAuth flow begins)
- `token.php` → HTTP 400 with JSON error (endpoint is alive)
- `user_info.php` → HTTP 401 or JSON error (endpoint is alive)

> ❌ If HTTP 404 → Plugin is not installed correctly  
> ❌ If HTTP 500 → Plugin has compatibility issues with Moodle 4.5

---

## 2.5 Create a Test User in Moodle

Create a few test accounts to verify the OAuth flow:

```bash
# Create test user via CLI
sudo -u www-data php /var/www/html/moodle/admin/cli/create_user.php \
  --username=testuser1 \
  --password=TestUser@123 \
  --email=testuser1@test.com \
  --firstname=Test \
  --lastname=User1
```

Or create manually via Web UI:
- **Site administration** → **Users** → **Add a new user**

---

## 2.6 Check Logs for Troubleshooting

```bash
# Apache error log
sudo tail -f /var/log/apache2/error.log

# Moodle log (via Web UI)
# Site administration → Reports → Live logs
```

---

## ✅ Checklist Step 2

- [ ] OAuth Plugin installed successfully
- [ ] Plugin appears in Plugins overview
- [ ] Created OAuth client with `client_id = JupyterHub`
- [ ] **Saved the new `client_secret`**
- [ ] `/local/oauth/login.php` endpoint returns HTTP 302/303 ✅
- [ ] `/local/oauth/token.php` endpoint does not return 404 ✅
- [ ] `/local/oauth/user_info.php` endpoint does not return 404 ✅
- [ ] No errors found in Apache error log

**→ Next step: `03_jupyterhub-oauth-test_en.md`**
