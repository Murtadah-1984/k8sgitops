# Push to GitHub Instructions

## Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `k8sgitops` (or your preferred name)
3. Description: "Helm-centric GitOps repository with ArgoCD"
4. Choose Private or Public
5. **DO NOT** check "Initialize with README" (we already have files)
6. Click "Create repository"

## Step 2: Push to GitHub

After creating the repository, GitHub will show you commands. Use these:

```bash
# Add the remote (replace YOUR-USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR-USERNAME/k8sgitops.git

# Push to GitHub
git push -u origin main
```

## Alternative: Using SSH

If you have SSH keys set up with GitHub:

```bash
# Add the remote (replace YOUR-USERNAME with your GitHub username)
git remote add origin git@github.com:YOUR-USERNAME/k8sgitops.git

# Push to GitHub
git push -u origin main
```

## Verify

After pushing, verify at: `https://github.com/YOUR-USERNAME/k8sgitops`

