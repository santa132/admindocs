# Step 3: Connect JupyterHub to Test Node

## Objectives
Temporarily update JupyterHub's `config.yaml` to point to the **Moodle test node**, verifying the entire OAuth flow functions correctly before upgrading production.

> ⚠️ **Important:** This step will **temporarily disconnect JupyterHub from Moodle production**.  
> Perform this action during low-traffic windows (after hours / weekends).

---

## 3.1 Backup Current config.yaml

```bash
# SSH into the Kubernetes node running JupyterHub (en1 / 192.168.33.15)
ssh <user>@192.168.33.15

# Backup production config.yaml
cp /path/to/config.yaml /path/to/config.yaml.backup_$(date +%Y%m%d)

# Verify backup
ls -la /path/to/config.yaml.backup_*
```

---

## 3.2 Collect Staging Details from Moodle Test Node

From Step 2, ensure you have:

| Parameter | Value |
|-----------|---------|
| **Test Node IP** | `192.168.33.3` |
| **Test Node Port** | `8889` |
| **client_id** | `JupyterHub` |
| **client_secret** | `<client_secret from step 2.3>` |

Verify endpoints:
```
authorize_url : http://192.168.33.3:8889/moodle/local/oauth/login.php?client_id=jupyterhub&response_type=code
token_url     : http://192.168.33.3:8889/moodle/local/oauth/token.php
userdata_url  : http://192.168.33.3:8889/moodle/local/oauth/user_info.php
```

---

## 3.3 Update config.yaml to Point to Moodle Test

Edit the JupyterHub `config.yaml` file (Helm values):

```yaml
hub:
  revisionHistoryLimit:
  config:
    GenericOAuthenticator:
      client_id: JupyterHub
      # Replace with client_secret from Moodle TEST NODE (step 2.3)
      client_secret: <NEW_CLIENT_SECRET_FROM_TEST>
      oauth_callback_url: http://login2.gpucluster.sutd.edu.sg/hub/oauth_callback

      # === POINT TO MOODLE TEST NODE ===
      authorize_url: http://192.168.33.3:8889/moodle/local/oauth/login.php?client_id=jupyterhub&response_type=code
      token_url: http://192.168.33.3:8889/moodle/local/oauth/token.php
      userdata_url: http://192.168.33.3:8889/moodle/local/oauth/user_info.php
      # =================================

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

---

## 3.4 Apply New Config

```bash
# Check namespace
kubectl get namespace | grep hub

# Apply new config
helm upgrade --cleanup-on-fail \
  --install hub jupyterhub/jupyterhub \
  --namespace hub \
  --create-namespace \
  --values config.yaml \
  --version 2.0

# Monitor deployment progress
kubectl --namespace=hub get pod -w
```

**Wait until all pods show `Running` status:**
```bash
kubectl --namespace=hub get pod
```

---

## 3.5 Verify OAuth Flow

### Test 1: Access JupyterHub

Open browser: `http://login2.gpucluster.sutd.edu.sg/hub`

→ It must redirect to the Moodle test node login page.

### Test 2: Log in with Test Account

1. Enter credentials of the test account created in step 2.5
2. Approve OAuth authorization request
3. It should redirect back to JupyterHub successfully

### Test 3: Verify User Creation in JupyterHub

```bash
# Check user list inside JupyterHub container
kubectl --namespace=hub exec -it deploy/hub -- \
  jupyterhub --show-config
```

Or open JupyterHub Admin panel: `http://login2.gpucluster.sutd.edu.sg/hub/admin`

### Test 4: Spawn Notebook Server

1. Login successfully
2. Select a server profile
3. Verify that the user pod starts successfully

---

## 3.6 Common Errors and Troubleshooting

### Error: `invalid_client` during OAuth Redirect

```
Cause: client_id or client_secret does not match.
Fix: Double check the client_secret in Moodle → OAuth provider settings.
```

### Error: `redirect_uri_mismatch`

```
Cause: Callback URL registered in Moodle doesn't match JupyterHub configuration.
Fix: Go to Moodle → OAuth provider settings → Edit Client → set Redirect URI to:
     http://login2.gpucluster.sutd.edu.sg/hub/oauth_callback
```

### Error: `Connection refused` when JupyterHub calls token_url

```
Cause: Firewall blocking connection from JupyterHub pods to the Test Node.
Fix: Open port 8889 on the test node:
     sudo ufw allow 8889/tcp
     or check iptables rules.
```

### Error: JupyterHub Pod Fails to Start

```bash
# View detailed logs
kubectl --namespace=hub logs deploy/hub --previous
kubectl --namespace=hub describe pod <hub-pod-name>
```

---

## 3.7 Revert Back to Production Configuration

Once testing is complete, **restore the original production config.yaml** to reconnect JupyterHub to Moodle production:

```bash
# Restore production config
cp /path/to/config.yaml.backup_$(date +%Y%m%d) /path/to/config.yaml

helm upgrade --cleanup-on-fail \
  --install hub jupyterhub/jupyterhub \
  --namespace hub \
  --create-namespace \
  --values config.yaml \
  --version 2.0
```

---

## ✅ Checklist Step 3

- [ ] Backed up production config.yaml
- [ ] Config file updated to point to test node
- [ ] JupyterHub redeployed successfully
- [ ] Accessing JupyterHub redirects to Moodle test ✅
- [ ] OAuth login successful with test user ✅
- [ ] Notebook server spawns successfully ✅
- [ ] No errors in logs

**→ If all checks pass: Proceed to `04_production-upgrade_en.md`**  
**→ If errors occur: Troubleshoot and fix before upgrading production**
