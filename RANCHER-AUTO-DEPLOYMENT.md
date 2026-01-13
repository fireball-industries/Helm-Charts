# Rancher Chart Repository Setup

**Self-Service Helm Chart Catalog for Multi-Tenant K3s**

Configure once. All tenants automatically see the chart catalog.

---

## Deployment Method

**Git Repository (Recommended)** ✅

Rancher clones your repo and auto-discovers all charts in the `charts/` directory.

**Why this method:**
- ✅ **Zero maintenance** - No manual index.yaml updates needed
- ✅ **Auto-discovery** - Push new charts, they appear automatically
- ✅ **Always in sync** - Polls every 15 minutes for changes
- ✅ **Developer friendly** - Just git push and go
- ✅ **Secure** - PAT stored encrypted in Rancher, revocable anytime

**Alternative: HTTP Index URL** ⚠️

*Not recommended for active development.* Requires:
- Manual `helm repo index charts/ --url https://...` after every change
- index.yaml must be in `charts/` directory (ours is in root)
- More maintenance, same security requirements for private repos

**Best for:** Static production catalogs where you manually control versions

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

**Note:** Git Subfolder field may not be visible in all Rancher versions. If you don't see it, leave it blank - Rancher auto-discovers charts in `charts/` folder by default.

### Step 3: Authentication (Private Repos Only)

**Public repo:** Leave blank

**Private repo:**
- **Type:** `HTTP Basic Auth`
- **Username:** GitHub username
- **Password:** GitHub Personal Access Token
  - Create at: https://github.com/settings/tokens
  - Scope: `repo` (required for cloning private repos)
  - **Security:** Token is encrypted in Rancher, used only for git clone operations

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

## Troubleshooting

### Problem: Rancher getting confused with too many charts

**Root Cause:** Rancher scanning the **entire repo** including `archive/` folder with old chart versions.

**The Fix:** Use `Git Subfolder: charts`

This tells Rancher to **only** scan the `charts/` directory and ignore:
- `archive/` folder (old charts)
- Root-level files (README, index.yaml, etc.)
- Any other directories

**Your repo structure:**
```
Helm-Charts/
├── archive/              ← Rancher IGNORES this
│   └── codesys-targetvisu/
├── charts/               ← Rancher ONLY scans this
│   ├── alert-manager/
│   ├── node-red/
│   ├── postgresql-pod/
│   └── ... (20 charts)
├── index.yaml            ← Rancher IGNORES this
└── README.md             ← Rancher IGNORES this
```

**Result:** Clean catalog with only your 20 production charts, no duplicates, no confusion.

---

## FAQ

### Do I need index.yaml in my repo?

**No.** When using Git repository method, Rancher ignores index.yaml and auto-discovers charts.

The `index.yaml` in the repo root is optional and can be used for:
- External Helm CLI users: `helm repo add ...`
- GitHub Pages hosting
- CI/CD validation

### What does Rancher actually clone?

Rancher clones the entire repository but only scans the `charts/` directory for valid Chart.yaml files. Each subdirectory with a Chart.yaml is treated as a Helm chart.

### How often does it sync?

Default: Every 15 minutes (configurable in Advanced Settings)

Manual sync: `Apps → Repositories → fireball-industries → ⋮ → Refresh`

### What if a chart is invalid?

Rancher skips invalid charts and displays errors in the repository status. Other valid charts still appear in the catalog.

### How many charts is too many?

Rancher can handle 100+ charts easily. Your 20 charts are fine. The confusion comes from Rancher scanning **both** `charts/` and `archive/` folders, creating duplicates.

**Solution:** `Git Subfolder: charts` - problem solved.

### How do I hide charts from tenants?

You don't need to. All 20 charts in `charts/` are production ready. Just make sure `Git Subfolder: charts` is set to avoid scanning the archive folder.

---

## Notes

- Works with automatic tenant watcher (no integration needed)
- New tenants automatically see the catalog
- Tenants control what they install and when they upgrade
- For forced deployments, see [FLEET-DEPLOYMENT.md](FLEET-DEPLOYMENT.md)
- **Git method requires no index.yaml maintenance** - Rancher auto-discovers charts

---

**Fireball Industries**
