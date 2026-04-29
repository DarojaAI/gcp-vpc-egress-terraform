# Release Process

## Automated Release Workflow

This repository uses automated releases triggered by VERSION file changes.

### How It Works

1. **Update VERSION file on main/master**
   ```bash
   echo "1.0.2" > VERSION
   git add VERSION
   git commit -m "chore: bump version to 1.0.2"
   git push origin master
   ```

2. **Auto-Trigger**
   - `.github/workflows/release.yml` detects VERSION change
   - Creates git tag: `v1.0.2`
   - Generates GitHub Release with automatic release notes
   - **Tag is created on main/master commit** (not feature branch)

### Important Notes

⚠️ **ALWAYS update VERSION on main/master, NEVER on feature branches**

**Correct workflow:**
```bash
# On main/master
git pull origin master
echo "1.0.2" > VERSION
git push origin master
# → Workflow auto-creates v1.0.2 tag ✅
```

**Incorrect workflow:**
```bash
# On feature branch
echo "1.0.2" > VERSION
git push origin fix/my-feature
# → Tag created on wrong branch ❌
```

### Manual Release (if needed)

```bash
# Ensure on main/master with latest changes
git checkout master
git pull origin master

# Create tag
git tag -a v1.0.2 -m "Release v1.0.2"
git push origin v1.0.2

# Create GitHub Release (optional, workflow will do this)
gh release create v1.0.2 --generate-notes
```

### Troubleshooting

**Tag points to wrong commit:**
```bash
# Delete wrong tag
git tag -d v1.0.2
git push origin :refs/tags/v1.0.2

# Recreate on correct commit
git checkout master
git pull origin master
echo "1.0.2" > VERSION
git push origin master
# Workflow will auto-create correct tag
```

**Workflow didn't trigger:**
- Check `.github/workflows/release.yml` exists
- Ensure VERSION file change was pushed to main/master
- Check Actions tab for logs

---

**Important:** Tags must always point to main/master commits, never feature branches. The automated workflow ensures this if you follow the process above.
