# Rancher Chart Repository Setup

**Self-Service Helm Chart Catalog for Multi-Tenant K3s**

Configure once. All tenants automatically see the chart catalog.

---

## Setup

### Step 1: Add GitHub Repository to Rancher

Navigate to:
```
Rancher UI → ☰ Menu → Apps → Repositories → Create
```

### Step 2: Configure

| Field | Value |
|-------|-------|
| **Name** | `fireball-industries` |
| **Target** | `Git repository containing Helm chart(s)` |
| **Git Repo URL** | `https://github.com/fireball-industries/Helm-Charts` |
| **Git Branch** | `main` |
| **Git Subfolder** | *(leave empty)* |

### Step 3: Authentication (Private Repos Only)

**Public repo:** Leave blank

**Private repo:**
- **Type:** `HTTP Basic Auth`
- **Username:** GitHub username
- **Password:** GitHub Personal Access Token
  - Create at: https://github.com/settings/tokens
  - Scope: `repo`

### Step 4: Advanced Settings

```
Poll Interval: 15m
Skip TLS Verification: false
```

### Step 5: Create

Click "Create". Wait 1-2 minutes for indexing.

### Step 6: Verify

```
Apps → Repositories → fireball-industries
```

Should show:
- Status: ✅ Active
- Chart Count: 20+
- Last Synced: Recent timestamp

**Done.** All tenants can now browse and install charts from `Apps → Charts`.

---

## How Tenants Use It

### View Available Charts
```
Rancher UI → Apps → Charts
```

### Install a Chart
```
Apps → Charts → [Select Chart] → Install
→ Choose namespace
→ Configure values
→ Click Install
```

### Upgrade a Chart
```
Apps → Installed Apps → [Find "Upgrade Available" badge]
→ Click app → Upgrade → Review → Upgrade
```

---

## Admin Tasks

### Force Catalog Refresh
```
Apps → Repositories → fireball-industries → ⋮ → Refresh
```

### Add New Chart
```bash
cd charts/
helm create my-new-chart
# Edit Chart.yaml, values.yaml, templates/
git add charts/my-new-chart/
git commit -m "Add my-new-chart"
git push
```

Wait 15 minutes or force refresh. Chart appears automatically.

### Update Existing Chart
```bash
cd charts/my-chart/
# Edit Chart.yaml (bump version)
# Edit templates/values as needed
git add charts/my-chart/
git commit -m "Update my-chart to v1.2.0"
git push
```

Tenants will see "Upgrade Available" badge. They control when to upgrade.

### Validate Before Push
```bash
helm lint charts/my-chart/
```

---

## Notes

- Works with automatic tenant watcher (no integration needed)
- New tenants automatically see the catalog
- Tenants control what they install and when they upgrade
- For forced deployments, see [FLEET-DEPLOYMENT.md](FLEET-DEPLOYMENT.md)

---

**Fireball Industries**
