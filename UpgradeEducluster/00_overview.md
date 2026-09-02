# Upgrade Plan: Moodle 4.0.2 → 4.5.12 (LTS)

## Goal
Upgrade Moodle from **4.0.2** to **4.5.12 (LTS)** to fix security vulnerability:
- **CVE-2024-45689** (Moodle Sensitive Information Disclosure / MSA-24-0042)

## Strategy: Test on Staging Node → Apply to Production

```
[STAGING/TEST NODE - 192.168.33.3]     [PRODUCTION NODE - 192.168.33.15]
 Moodle 4.5.12 (Fresh Install)       →   Moodle 4.0.2 (Active Production)
 Test OAuth Plugin                       Upgrade to 4.5.12 after staging test
 Test JupyterHub Integration
```

## Document Structure

| File | Content Description |
|------|---------------------|
| `00_overview_en.md` | Strategic overview (This file) |
| `01_test-node-setup_en.md` | Step 1: Install Moodle 4.5.12 on test node (`192.168.33.3`) |
| `02_oauth-plugin-test_en.md` | Step 2: Install and verify OAuth Plugin on test node |
| `03_jupyterhub-oauth-test_en.md` | Step 3: Connect JupyterHub to test node for verification |
| `04_production-upgrade_en.md` | Step 4: Step-by-step Moodle production upgrade guide |
| `05_rollback_en.md` | Step 5: Rollback plan in case of issues |

## System Specifications (Production)

| Component | Specification |
|------------|---------------|
| **Host** | `192.168.33.15` |
| **Moodle Port** | `8888` |
| **URL** | `http://login2.gpucluster.sutd.edu.sg:8888/moodle` |
| **Moodle Version** | 4.0.2 (`MOODLE_402_STABLE`) |
| **PHP Version** | 8.1 |
| **Database** | MariaDB |
| **OAuth Plugin** | `oauth_gn4.zip` (`local/oauth`) |

## Moodle 4.5 Compatibility Requirements

| Component | Required | Present |
|-----------|----------|---------|
| PHP | >= 8.1.0 | ✅ PHP 8.1 |
| MariaDB | >= 10.6.7 | ✅ MariaDB 10.11 |

## Important Warnings
> ⚠️ **DO NOT** modify JupyterHub production `config.yaml` until the test stage is fully verified.  
> ⚠️ Ensure database backups are verified before upgrading production.  
> ⚠️ OAuth `client_secret` will change after re-installing the plugin; it must be updated in JupyterHub.
